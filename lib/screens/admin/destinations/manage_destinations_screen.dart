import 'package:flutter/material.dart';

import '../../../models/destination.dart';
import '../../../repositories/destination_repository.dart';
import '../../../services/cloudinary_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'destination_form_screen.dart';

class ManageDestinationsScreen extends StatefulWidget {
  const ManageDestinationsScreen({super.key});

  @override
  State<ManageDestinationsScreen> createState() =>
      _ManageDestinationsScreenState();
}

class _ManageDestinationsScreenState extends State<ManageDestinationsScreen> {
  final DestinationRepository _repository = DestinationRepository();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _popularFilter = 'All'; // All, Popular, Not Popular

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
            'Manage Destinations',
            style: AppTextStyles.screenHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ),
        _buildFilters(),
        Expanded(
          child: StreamBuilder<List<Destination>>(
            stream: _repository.getDestinationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Couldn\'t load destinations.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              final allDestinations = snapshot.data ?? [];
              final filteredDestinations = _filterDestinations(allDestinations);

              if (filteredDestinations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No destinations found.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _openForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('+ Add Destination'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: filteredDestinations.length,
                itemBuilder: (context, index) {
                  final dest = filteredDestinations[index];
                  return _buildDestinationCard(dest);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<Destination> _filterDestinations(List<Destination> all) {
    return all.where((dest) {
      // Search
      final matchesSearch =
          dest.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          dest.locationName.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      // Status Filter
      if (_statusFilter == 'Active' && !dest.isActive) return false;
      if (_statusFilter == 'Inactive' && dest.isActive) return false;

      // Popular Filter
      if (_popularFilter == 'Popular' && !dest.isPopular) return false;
      if (_popularFilter == 'Not Popular' && dest.isPopular) return false;

      return true;
    }).toList();
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search destinations...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton(
                onPressed: _openForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: const Text('+ Add'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Status',
                  ['All', 'Active', 'Inactive'],
                  _statusFilter,
                  (val) => setState(() => _statusFilter = val),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildFilterChip(
                  'Popularity',
                  ['All', 'Popular', 'Not Popular'],
                  _popularFilter,
                  (val) => setState(() => _popularFilter = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    List<String> options,
    String currentValue,
    Function(String) onChanged,
  ) {
    return Row(
      children: [
        Text(
          '$label:',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: currentValue,
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

  Widget _buildDestinationCard(Destination dest) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.background,
                image: dest.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(dest.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: dest.imageUrl == null
                  ? const Icon(Icons.image, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest.locationName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest.shortDescription,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (dest.isPopular) ...[
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Popular',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: dest.isActive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dest.isActive ? 'Active' : 'Inactive',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => _openForm(dest: dest),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(
                    dest.isActive ? Icons.block : Icons.check_circle_outline,
                    color: dest.isActive ? Colors.red : Colors.green,
                  ),
                  onPressed: () => _confirmToggleActive(dest),
                  tooltip: dest.isActive ? 'Deactivate' : 'Reactivate',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(dest),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openForm({Destination? dest}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DestinationFormScreen(destination: dest),
      ),
    );
  }

  void _confirmToggleActive(Destination dest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          dest.isActive ? 'Deactivate Destination?' : 'Reactivate Destination?',
        ),
        content: Text(
          dest.isActive
              ? 'Are you sure you want to deactivate "${dest.name}"? It will no longer be visible to travelers.'
              : 'Are you sure you want to reactivate "${dest.name}"? It will become visible to travelers again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (dest.isActive) {
                _repository.deactivateDestination(dest.id);
              } else {
                _repository.reactivateDestination(dest.id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Destination ${dest.isActive ? 'deactivated' : 'reactivated'} successfully',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dest.isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(dest.isActive ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Destination dest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Destination?'),
        content: const Text(
          'This will remove the destination from the app and delete its associated image.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog

              try {
                // 1. Delete Firestore Document
                await _repository.deleteDestination(dest.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Destination deleted successfully'),
                    ),
                  );
                }

                // 2. Delete Cloudinary Image (if public ID exists)
                if (dest.imagePublicId != null) {
                  final bool deleted = await _cloudinaryService.deleteImage(
                    dest.imagePublicId!,
                  );
                  if (!deleted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Destination deleted, but image could not be automatically removed from media storage.',
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                }
              } catch (e) {
                // If Firestore deletion fails, it will be caught here and Cloudinary won't be touched.
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete destination: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
