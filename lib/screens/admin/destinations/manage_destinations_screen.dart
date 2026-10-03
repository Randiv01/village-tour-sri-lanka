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

  late Stream<List<Destination>> _destinationsStream = _repository
      .getDestinationsStream();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _popularFilter = 'All'; // All, Popular, Not Popular
  String _sortBy =
      'Display Order'; // Display Order, Name A-Z, Name Z-A, Newest, Oldest

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
    _destinationsStream = _repository.getDestinationsStream();
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
            'Manage Destinations',
            style: AppTextStyles.screenHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ),
        _buildTopBar(),
        Expanded(
          child: StreamBuilder<List<Destination>>(
            stream: _destinationsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState();
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              final allDestinations = snapshot.data ?? [];
              if (allDestinations.isEmpty) {
                return _buildDatabaseEmptyState();
              }

              final filteredDestinations = _filterAndSortDestinations(
                allDestinations,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultCount(filteredDestinations.length),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.primary,
                      child: filteredDestinations.isEmpty
                          ? _buildFilterEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filteredDestinations.length,
                              itemBuilder: (context, index) {
                                final dest = filteredDestinations[index];
                                return _buildDestinationCard(dest);
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
                hintText: 'Search destinations...',
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
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: _openForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
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
    String tempPopular = _popularFilter;
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
                tempStatus != _statusFilter ||
                tempPopular != _popularFilter ||
                tempSort != _sortBy;
            final bool hasFilters =
                tempStatus != 'All' ||
                tempPopular != 'All' ||
                tempSort != 'Display Order';

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
                    'Popularity',
                    ['All', 'Popular', 'Not Popular'],
                    tempPopular,
                    (val) => setSheetState(() => tempPopular = val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSheetDropdown(
                    'Sort By',
                    [
                      'Display Order',
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
                                    tempPopular = 'All';
                                    tempSort = 'Display Order';
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
                                    _popularFilter = tempPopular;
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
      _popularFilter = 'All';
      _sortBy = 'Display Order';
    });
  }

  Widget _buildResultCount(int count) {
    String text;
    if (count == 1) {
      text = '1 destination found';
    } else {
      text = '$count destinations found';
    }
    if (_searchQuery.isEmpty &&
        _statusFilter == 'All' &&
        _popularFilter == 'All') {
      text = count == 1 ? '1 destination' : '$count destinations';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  List<Destination> _filterAndSortDestinations(List<Destination> all) {
    final filtered = all.where((dest) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesSearch =
            dest.name.toLowerCase().contains(query) ||
            dest.locationName.toLowerCase().contains(query) ||
            dest.shortDescription.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      if (_statusFilter == 'Active' && !dest.isActive) return false;
      if (_statusFilter == 'Inactive' && dest.isActive) return false;

      if (_popularFilter == 'Popular' && !dest.isPopular) return false;
      if (_popularFilter == 'Not Popular' && dest.isPopular) return false;

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Name A-Z':
          return a.name.compareTo(b.name);
        case 'Name Z-A':
          return b.name.compareTo(a.name);
        case 'Newest':
          return b.createdAt.compareTo(a.createdAt);
        case 'Oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'Display Order':
        default:
          return a.displayOrder.compareTo(b.displayOrder);
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
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
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
            'We couldn\'t load destinations',
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
            Icons.place_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No destinations yet', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 8),
          Text(
            'Add your first destination to get started.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
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
              'No destinations match your filters',
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

  Widget _buildDestinationCard(Destination dest) {
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
                child:
                    (dest.images.isNotEmpty ||
                        (dest.imageUrl != null && dest.imageUrl!.isNotEmpty))
                    ? Image.network(
                        dest.images.isNotEmpty
                            ? dest.images.first.url
                            : dest.imageUrl!,
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
                    dest.name,
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
                          dest.locationName,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest.shortDescription,
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
                        dest.isActive ? 'Active' : 'Inactive',
                        dest.isActive ? Icons.check : Icons.close,
                        dest.isActive ? Colors.green : AppColors.error,
                      ),
                      if (dest.isPopular)
                        _buildBadge('Popular', Icons.star, AppColors.tertiary),
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
                            dest.images.length == 1
                                ? '1 image'
                                : '${dest.images.length} images',
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
                              color: AppColors.primary,
                            ),
                            onPressed: () => _openForm(dest: dest),
                            tooltip: 'Edit',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              dest.isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: dest.isActive
                                  ? AppColors.textSecondary
                                  : Colors.green,
                            ),
                            onPressed: () {
                              if (dest.isActive) {
                                _confirmDeactivate(dest);
                              } else {
                                _activateDestination(dest);
                              }
                            },
                            tooltip: dest.isActive ? 'Deactivate' : 'Activate',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: () => _confirmDelete(dest),
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
            ),
          ),
        ],
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

  void _confirmDeactivate(Destination dest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide destination?'),
        content: const Text(
          'Destination will no longer be visible to travelers, but its data will be kept.',
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
              Navigator.of(context).pop();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _repository.deactivateDestination(dest.id);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Destination deactivated successfully.'),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Deactivate error: $e');
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'We couldn\'t complete this action. Please try again.',
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateDestination(Destination dest) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repository.reactivateDestination(dest.id);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Destination activated successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Activate error: $e');
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'We couldn\'t complete this action. Please try again.',
            ),
          ),
        );
      }
    }
  }

  void _confirmDelete(Destination dest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete destination?'),
        content: Text(
          'This will permanently remove ${dest.name} from the system.',
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
              Navigator.of(context).pop();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _repository.deleteDestination(dest.id);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Destination deleted successfully.'),
                    ),
                  );
                }

                if (dest.imagePublicId != null) {
                  _cloudinaryService
                      .deleteImage(dest.imagePublicId!)
                      .catchError((e) {
                        debugPrint('Silently failed to delete image: $e');
                        return false;
                      });
                }
              } catch (e) {
                debugPrint('Delete error: $e');
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'We couldn\'t complete this action. Please try again.',
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
