import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/tour_package.dart';
import '../../../repositories/tour_package_repository.dart';
import 'create_edit_package_screen.dart';
import 'package_management_screen.dart';

class GuidePackagesScreen extends StatefulWidget {
  const GuidePackagesScreen({super.key});

  @override
  State<GuidePackagesScreen> createState() => _GuidePackagesScreenState();
}

class _GuidePackagesScreenState extends State<GuidePackagesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  
  String _statusFilter = 'All'; 
  String _categoryFilter = 'All Categories';
  String _durationFilter = 'Any duration';
  String _priceFilter = 'Any price';
  String _sortOrder = 'Newest';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  
  void _clearFilters() {
    setState(() {
      _statusFilter = 'All';
      _categoryFilter = 'All Categories';
      _durationFilter = 'Any duration';
      _priceFilter = 'Any price';
      _sortOrder = 'Newest';
    });
  }
  
  void _showFilterSheet(List<TourPackage> allPackages) {
    // Get unique categories for the filter
    final categories = ['All Categories'];
    final uniqueCategories = allPackages.map((p) => p.category).whereType<String>().toSet().toList();
    uniqueCategories.sort();
    categories.addAll(uniqueCategories);
    
    // Copy current state to temporary variables for the bottom sheet
    String tempStatus = _statusFilter;
    String tempCategory = _categoryFilter;
    String tempDuration = _durationFilter;
    String tempPrice = _priceFilter;
    String tempSort = _sortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status', style: AppTextStyles.labelLarge),
                        Wrap(
                          spacing: 8,
                          children: ['All', 'Active', 'Inactive', 'Draft'].map((s) => ChoiceChip(
                            label: Text(s),
                            selected: tempStatus == s,
                            onSelected: (val) { if (val) setModalState(() => tempStatus = s); },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: tempStatus == s ? AppColors.primaryDark : AppColors.textPrimary),
                          )).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        Text('Category', style: AppTextStyles.labelLarge),
                        Wrap(
                          spacing: 8,
                          children: categories.map((c) => ChoiceChip(
                            label: Text(c),
                            selected: tempCategory == c,
                            onSelected: (val) { if (val) setModalState(() => tempCategory = c); },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: tempCategory == c ? AppColors.primaryDark : AppColors.textPrimary),
                          )).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        Text('Duration', style: AppTextStyles.labelLarge),
                        Wrap(
                          spacing: 8,
                          children: ['Any duration', '1 day', '2-3 days', '4-7 days', '8+ days'].map((d) => ChoiceChip(
                            label: Text(d),
                            selected: tempDuration == d,
                            onSelected: (val) { if (val) setModalState(() => tempDuration = d); },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: tempDuration == d ? AppColors.primaryDark : AppColors.textPrimary),
                          )).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        Text('Sort By', style: AppTextStyles.labelLarge),
                        Wrap(
                          spacing: 8,
                          children: ['Newest', 'Oldest', 'Price: Low to High', 'Price: High to Low', 'Name: A-Z'].map((s) => ChoiceChip(
                            label: Text(s),
                            selected: tempSort == s,
                            onSelected: (val) { if (val) setModalState(() => tempSort = s); },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: tempSort == s ? AppColors.primaryDark : AppColors.textPrimary),
                          )).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempStatus = 'All';
                              tempCategory = 'All Categories';
                              tempDuration = 'Any duration';
                              tempPrice = 'Any price';
                              tempSort = 'Newest';
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = tempStatus;
                              _categoryFilter = tempCategory;
                              _durationFilter = tempDuration;
                              _priceFilter = tempPrice;
                              _sortOrder = tempSort;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _matchesFilter(TourPackage p) {
    if (_searchQuery.isNotEmpty) {
      if (!p.title.toLowerCase().contains(_searchQuery) &&
          !(p.category?.toLowerCase().contains(_searchQuery) ?? false) &&
          !p.location.toLowerCase().contains(_searchQuery)) {
        return false;
      }
    }
    
    if (_statusFilter != 'All' && p.status.toLowerCase() != _statusFilter.toLowerCase()) {
      return false;
    }
    
    if (_categoryFilter != 'All Categories' && p.category != _categoryFilter) {
      return false;
    }
    
    if (_durationFilter != 'Any duration') {
      if (_durationFilter == '1 day' && p.durationDays != 1) return false;
      if (_durationFilter == '2-3 days' && (p.durationDays < 2 || p.durationDays > 3)) return false;
      if (_durationFilter == '4-7 days' && (p.durationDays < 4 || p.durationDays > 7)) return false;
      if (_durationFilter == '8+ days' && p.durationDays < 8) return false;
    }
    
    return true;
  }
  
  int _comparePackages(TourPackage a, TourPackage b) {
    if (_sortOrder == 'Newest') {
      return (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000));
    } else if (_sortOrder == 'Oldest') {
      return (a.createdAt ?? DateTime(2000)).compareTo(b.createdAt ?? DateTime(2000));
    } else if (_sortOrder == 'Price: Low to High') {
      return a.pricePerGuest.compareTo(b.pricePerGuest);
    } else if (_sortOrder == 'Price: High to Low') {
      return b.pricePerGuest.compareTo(a.pricePerGuest);
    } else if (_sortOrder == 'Name: A-Z') {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final repo = TourPackageRepository();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('My Tour Packages', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search, Filter, and Add row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim().toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search destinations...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StreamBuilder<List<TourPackage>>(
                  stream: repo.getGuidePackagesStream(uid),
                  builder: (context, snapshot) {
                    final allPackages = snapshot.data ?? [];
                    final hasActiveFilters = _statusFilter != 'All' || _categoryFilter != 'All Categories' || _durationFilter != 'Any duration' || _sortOrder != 'Newest';
                    
                    return GestureDetector(
                      onTap: () => _showFilterSheet(allPackages),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: hasActiveFilters ? AppColors.primary : AppColors.border.withValues(alpha: 0.3), width: hasActiveFilters ? 2 : 1),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.tune, color: hasActiveFilters ? AppColors.primary : AppColors.primaryDark, size: 22),
                            if (hasActiveFilters)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEditPackageScreen())),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text('Add', style: AppTextStyles.buttonText.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<TourPackage>>(
              stream: repo.getGuidePackagesStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text('Unable to load tour packages.', style: AppTextStyles.bodyLarge),
                      Text(snapshot.error.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ]),
                  ));
                }
                
                final allPackages = snapshot.data ?? [];
                
                if (allPackages.isEmpty) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.explore_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: AppSpacing.lg),
                      Text('No tour packages yet.', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Create your first tour package and start welcoming travelers.', textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Tour Package'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEditPackageScreen())),
                      ),
                    ]),
                  ));
                }

                var filteredPackages = allPackages.where(_matchesFilter).toList();
                filteredPackages.sort(_comparePackages);
                
                if (filteredPackages.isEmpty) {
                  final isFilterOnly = _searchQuery.isEmpty;
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: AppSpacing.lg),
                      Text(isFilterOnly ? 'No packages match your filters.' : 'No packages found.', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Try adjusting your search or filters.', textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
                      const SizedBox(height: AppSpacing.xl),
                      if (isFilterOnly)
                        OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear Filters'),
                        ),
                    ]),
                  ));
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text('${filteredPackages.length} destinations', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                        itemCount: filteredPackages.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final pkg = filteredPackages[index];
                          return _PackageListItem(
                            package: pkg,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageManagementScreen(package: pkg))),
                            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEditPackageScreen(package: pkg))),
                            onDelete: () => _confirmDelete(pkg, repo),
                            onToggleStatus: () {
                              final newStatus = pkg.isActive ? 'inactive' : 'active';
                              repo.updatePackageStatus(pkg.id, newStatus);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Package marked as $newStatus.')));
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete(TourPackage package, TourPackageRepository repo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tour Package?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final hasBookings = await repo.hasBookings(package.id, package.guideId);
                if (hasBookings) {
                  await repo.updatePackageStatus(package.id, 'inactive');
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package has bookings and was marked as inactive instead of deleted.')));
                } else {
                  await repo.deletePackage(package.id);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tour package deleted successfully.')));
                }
              } catch (e) {
                 if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong. Please try again. ($e)'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PackageListItem extends StatelessWidget {
  final TourPackage package; 
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  
  const _PackageListItem({
    required this.package, 
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface, 
          borderRadius: AppRadius.cardRadius, 
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)), 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.cards)),
              child: SizedBox(
                width: 110, 
                height: 140,
                child: package.coverImageUrl != null && package.coverImageUrl!.isNotEmpty
                    ? Image.network(package.coverImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.softSecondarySurface, child: const Icon(Icons.image, color: AppColors.textSecondary)))
                    : Container(color: AppColors.softSecondarySurface, child: Icon(Icons.explore, color: AppColors.primary.withValues(alpha: 0.3), size: 32)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(package.title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(child: Text(package.location, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(package.category ?? package.description, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: package.isActive ? Colors.green.withValues(alpha: 0.1) : AppColors.softSecondarySurface, 
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: package.isActive ? Colors.green.withValues(alpha: 0.5) : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(package.isActive ? Icons.check : Icons.close, size: 10, color: package.isActive ? Colors.green : AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(package.isActive ? 'Active' : package.status.capitalize(), style: AppTextStyles.caption.copyWith(color: package.isActive ? Colors.green : AppColors.textSecondary, fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 10, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('Popular', style: AppTextStyles.caption.copyWith(color: Colors.orange, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${package.galleryImages.length + (package.coverImageUrl != null ? 1 : 0)} images', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        const Spacer(),
                        GestureDetector(
                          onTap: onEdit,
                          child: const Icon(Icons.edit, size: 18, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        GestureDetector(
                          onTap: onToggleStatus,
                          child: Icon(package.isActive ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return "";
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}
