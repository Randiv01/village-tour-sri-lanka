import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../models/homestay.dart';
import 'add_homestay_screen.dart';
import 'update_homestay_screen.dart';

class ManageHomestaysScreen extends StatefulWidget {
  const ManageHomestaysScreen({super.key});

  @override
  State<ManageHomestaysScreen> createState() => _ManageHomestaysScreenState();
}

class _ManageHomestaysScreenState extends State<ManageHomestaysScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _guestsFilter = 'All'; // All, 1-2 Guests, 3-4 Guests, 5+ Guests
  String _sortBy = 'Newest'; // Newest, Oldest, Price High-Low, Price Low-High

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddHomestayScreen()),
    );
  }

  void _openEditForm(Homestay homestay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateHomestayScreen(homestay: homestay),
      ),
    );
  }

  Future<void> _toggleStatus(String id, bool currentIsActive) async {
    await FirebaseFirestore.instance.collection('homestays').doc(id).update({
      'status': currentIsActive ? 'Inactive' : 'Active',
    });
  }

  Future<void> _deleteHomestay(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Homestay?'),
        content: const Text(
          'Are you sure you want to delete this homestay? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('homestays').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Center(
                child: Text(
                  'Manage Homestays',
                  style: AppTextStyles.screenHeading.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            _buildTopBar(),
            Expanded(child: _buildHomestaysList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search homestays...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.primary),
            onPressed: _showFilterSortSheet,
            tooltip: 'Filters & Sort',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: _openAddForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('+ Add'),
          ),
        ],
      ),
    );
  }

  void _showFilterSortSheet() {
    String tempStatus = _statusFilter;
    String tempGuests = _guestsFilter;
    String tempSort = _sortBy;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bool hasFilters =
                tempStatus != 'All' ||
                tempGuests != 'All' ||
                tempSort != 'Newest';

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters & Sort',
                        style: AppTextStyles.sectionHeading,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSheetDropdown(
                    'Status',
                    ['All', 'Active', 'Inactive'],
                    tempStatus,
                    (val) => setSheetState(() => tempStatus = val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSheetDropdown(
                    'Guests',
                    ['All', '1-2 Guests', '3-4 Guests', '5+ Guests'],
                    tempGuests,
                    (val) => setSheetState(() => tempGuests = val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSheetDropdown(
                    'Sort By',
                    ['Newest', 'Oldest', 'Price High-Low', 'Price Low-High'],
                    tempSort,
                    (val) => setSheetState(() => tempSort = val),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: hasFilters
                              ? () {
                                  setSheetState(() {
                                    tempStatus = 'All';
                                    tempGuests = 'All';
                                    tempSort = 'Newest';
                                  });
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: hasFilters
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: hasFilters
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = tempStatus;
                              _guestsFilter = tempGuests;
                              _sortBy = tempSort;
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetDropdown(
    String label,
    List<String> options,
    String value,
    Function(String) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: options
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: AppTextStyles.bodyMedium),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildHomestaysList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('homestays')
          .where('hostId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        // Convert to list for filtering & sorting
        var homestays = docs.map((doc) {
          return Homestay.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // Apply filters
        homestays = homestays.where((item) {
          final title = item.title.toLowerCase();
          final location = item.location.toLowerCase();
          final status = item.status;

          if (_searchQuery.isNotEmpty &&
              !title.contains(_searchQuery) &&
              !location.contains(_searchQuery)) {
            return false;
          }
          if (_statusFilter != 'All' && status != _statusFilter) {
            return false;
          }
          if (_guestsFilter != 'All') {
            if (_guestsFilter == '1-2 Guests' && item.maxGuests > 2) {
              return false;
            }
            if (_guestsFilter == '3-4 Guests' &&
                (item.maxGuests < 3 || item.maxGuests > 4)) {
              return false;
            }
            if (_guestsFilter == '5+ Guests' && item.maxGuests < 5) {
              return false;
            }
          }
          return true;
        }).toList();

        // Apply sorting
        homestays.sort((a, b) {
          final priceA = a.pricePerNight;
          final priceB = b.pricePerNight;

          final timeA = a.createdAt;
          final timeB = b.createdAt;

          if (_sortBy == 'Price High-Low') {
            return priceB.compareTo(priceA);
          } else if (_sortBy == 'Price Low-High') {
            return priceA.compareTo(priceB);
          } else if (_sortBy == 'Oldest') {
            if (timeA == null || timeB == null) return 0;
            return timeA.compareTo(timeB);
          } else {
            // Newest
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          }
        });

        if (homestays.isEmpty) {
          return _buildFilterEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: homestays.length,
          itemBuilder: (context, index) {
            final item = homestays[index];
            return _buildHomestayCard(item);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No homestays listed yet', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 8),
          Text(
            'Add your first homestay to start earning.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openAddForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('+ Add Homestay'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No homestays match your filters',
            style: AppTextStyles.sectionHeading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _statusFilter = 'All';
                _guestsFilter = 'All';
                _sortBy = 'Newest';
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomestayCard(Homestay homestay) {
    final isActive = homestay.status == 'Active';
    final coverImage = homestay.coverImage;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                color: AppColors.background,
                child: coverImage != null
                    ? Image.network(
                        coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image,
                              color: AppColors.textSecondary,
                            ),
                      )
                    : const Icon(Icons.image, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    homestay.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          homestay.location,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    homestay.description,
                    style: AppTextStyles.bodySecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBadge(
                        isActive ? 'Active' : 'Inactive',
                        isActive ? Icons.check : Icons.close,
                        isActive ? Colors.green : AppColors.error,
                      ),
                      _buildBadge(
                        'Rs. ${homestay.pricePerNight}/night',
                        Icons.payments,
                        AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.photo_camera,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            homestay.images.length == 1
                                ? '1 image'
                                : '${homestay.images.length} images',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.primaryDark,
                            ),
                            onPressed: () => _openEditForm(homestay),
                            tooltip: 'Edit',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: isActive
                                  ? AppColors.textSecondary
                                  : Colors.green,
                            ),
                            onPressed: () =>
                                _toggleStatus(homestay.id, isActive),
                            tooltip: isActive ? 'Deactivate' : 'Activate',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: () => _deleteHomestay(homestay.id),
                            tooltip: 'Delete',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
