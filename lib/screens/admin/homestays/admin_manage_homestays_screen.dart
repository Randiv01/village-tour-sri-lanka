import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/homestay.dart';
import '../../../repositories/homestay_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../host/homestays/update_homestay_screen.dart';

class AdminManageHomestaysScreen extends StatefulWidget {
  const AdminManageHomestaysScreen({super.key});

  @override
  State<AdminManageHomestaysScreen> createState() =>
      _AdminManageHomestaysScreenState();
}

class _AdminManageHomestaysScreenState
    extends State<AdminManageHomestaysScreen> {
  final HomestayRepository _repository = HomestayRepository();

  late Stream<List<Homestay>> _homestaysStream = _repository.getAllHomestays();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _sortBy = 'Newest'; // Name A-Z, Name Z-A, Newest, Oldest

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStream() {
    _homestaysStream = _repository.getAllHomestays();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadStream();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            'Manage Homestays',
            style: AppTextStyles.screenHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ),
        _buildTopBar(),
        Expanded(
          child: StreamBuilder<List<Homestay>>(
            stream: _homestaysStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState();
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              final allHomestays = snapshot.data ?? [];
              if (allHomestays.isEmpty) {
                return _buildDatabaseEmptyState();
              }

              final filteredHomestays = _filterAndSortHomestays(allHomestays);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultCount(filteredHomestays.length),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.primary,
                      child: filteredHomestays.isEmpty
                          ? _buildFilterEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filteredHomestays.length,
                              itemBuilder: (context, index) {
                                final hs = filteredHomestays[index];
                                return _buildHomestayCard(hs);
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
                  _searchQuery = val;
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
        ],
      ),
    );
  }

  void _showFilterSortSheet() {
    String tempStatus = _statusFilter;
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
            final bool hasChanges =
                tempStatus != _statusFilter || tempSort != _sortBy;
            final bool hasFilters =
                tempStatus != 'All' || tempSort != 'Newest';

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
                    'Sort By',
                    [
                      'Name A-Z',
                      'Name Z-A',
                      'Newest',
                      'Oldest',
                    ],
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
                          onPressed: hasChanges
                              ? () {
                                  setState(() {
                                    _statusFilter = tempStatus;
                                    _sortBy = tempSort;
                                  });
                                  Navigator.of(context).pop();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = 'All';
      _sortBy = 'Newest';
    });
  }

  Widget _buildResultCount(int count) {
    String text;
    if (count == 1) {
      text = '1 homestay found';
    } else {
      text = '$count homestays found';
    }
    if (_searchQuery.isEmpty && _statusFilter == 'All') {
      text = count == 1 ? '1 homestay' : '$count homestays';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  List<Homestay> _filterAndSortHomestays(List<Homestay> all) {
    final filtered = all.where((hs) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesSearch =
            hs.title.toLowerCase().contains(query) ||
            hs.location.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      if (_statusFilter == 'Active' && hs.status != 'Active') return false;
      if (_statusFilter == 'Inactive' && hs.status == 'Active') return false;

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Name A-Z':
          return a.title.compareTo(b.title);
        case 'Name Z-A':
          return b.title.compareTo(a.title);
        case 'Oldest':
          return (a.createdAt ?? DateTime.now())
              .compareTo(b.createdAt ?? DateTime.now());
        case 'Newest':
        default:
          return (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now());
      }
    });

    return filtered;
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 16,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'We couldn\'t load homestays',
            style: AppTextStyles.sectionHeading,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loadStream();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.house_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No homestays yet', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 8),
          Text(
            'Hosts haven\'t added any homestays yet.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              onPressed: _clearFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomestayCard(Homestay hs) {
    bool isActive = hs.status == 'Active';
    String imageUrl = hs.coverImage ?? (hs.images.isNotEmpty ? hs.images.first : '');

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
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            color: AppColors.textSecondary,
                          );
                        },
                      )
                    : const Icon(Icons.house, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hs.title,
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
                          hs.location,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                        'Rs. ${hs.pricePerNight.toStringAsFixed(0)}',
                        Icons.payments_outlined,
                        AppColors.primary,
                      ),
                      if (hs.isVerified)
                        _buildBadge(
                          'Verified',
                          Icons.verified,
                          Colors.blue,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateHomestayScreen(homestay: hs),
                                ),
                              ).then((_) => _loadStream());
                            },
                            tooltip: 'Edit',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          ),
                          IconButton(
                            icon: Icon(
                              hs.isVerified ? Icons.verified : Icons.new_releases_outlined,
                              color: hs.isVerified ? Colors.blue : AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => _toggleHomestayVerification(hs),
                            tooltip: hs.isVerified ? 'Unverify' : 'Verify',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          ),
                          IconButton(
                            icon: Icon(
                              isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: isActive
                                  ? AppColors.textSecondary
                                  : Colors.green,
                              size: 20,
                            ),
                            onPressed: () {
                              if (isActive) {
                                _confirmDeactivate(hs);
                              } else {
                                _activateHomestay(hs);
                              }
                            },
                            tooltip: isActive ? 'Deactivate' : 'Activate',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () => _confirmDelete(hs),
                            tooltip: 'Delete',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

  Future<void> _activateHomestay(Homestay hs) async {
    try {
      await FirebaseFirestore.instance
          .collection('homestays')
          .doc(hs.id)
          .update({'status': 'Active'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homestay activated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate homestay: $e')),
        );
      }
    }
  }

  Future<void> _toggleHomestayVerification(Homestay hs) async {
    final newStatus = !hs.isVerified;
    try {
      await FirebaseFirestore.instance
          .collection('homestays')
          .doc(hs.id)
          .update({'isVerified': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(newStatus
                  ? 'Homestay verified successfully'
                  : 'Homestay unverified')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update verification status: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeactivate(Homestay hs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Homestay?'),
        content: Text(
            'Are you sure you want to deactivate "${hs.title}"? It will no longer be visible to travelers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('homestays')
            .doc(hs.id)
            .update({'status': 'Inactive'});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Homestay deactivated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to deactivate homestay: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(Homestay hs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Homestay?'),
        content: Text(
            'Are you sure you want to delete "${hs.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('homestays').doc(hs.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Homestay deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete homestay: $e')),
          );
        }
      }
    }
  }
}
