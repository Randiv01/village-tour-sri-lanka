import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
                                _searchQuery = val.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search packages...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.tune, color: AppColors.primaryDark, size: 22),
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
                    ]),
                  ));
                }
                
                final allPackages = snapshot.data ?? [];
                
                final packages = _searchQuery.isEmpty 
                    ? allPackages 
                    : allPackages.where((p) => p.title.toLowerCase().contains(_searchQuery)).toList();
                
                if (packages.isEmpty) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.explore_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: AppSpacing.lg),
                      Text('No tour packages found', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(allPackages.isEmpty ? 'Create your first village tour package and start welcoming travelers.' : 'Try adjusting your search.', textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
                      if (allPackages.isEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create Tour Package'),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEditPackageScreen())),
                        ),
                      ],
                    ]),
                  ));
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_searchQuery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text('${packages.length} packages', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                        itemCount: packages.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final pkg = packages[index];
                          return _PackageListItem(
                            package: pkg,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageManagementScreen(package: pkg))),
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
}

class _PackageListItem extends StatelessWidget {
  final TourPackage package; 
  final VoidCallback onTap;
  
  const _PackageListItem({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.cards)),
            child: SizedBox(width: 90, height: 110,
              child: package.coverImageUrl != null && package.coverImageUrl!.isNotEmpty
                  ? Image.network(package.coverImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.softSecondarySurface, child: const Icon(Icons.image, color: AppColors.textSecondary)))
                  : Container(color: AppColors.softSecondarySurface, child: Icon(Icons.explore, color: AppColors.primary.withValues(alpha: 0.3), size: 32)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(package.title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${package.durationDays} Days / ${package.nights} Nights', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              Text('Up to ${package.maxGuests} Guests', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: package.isActive ? Colors.green.withValues(alpha: 0.1) : AppColors.softSecondarySurface, borderRadius: BorderRadius.circular(10)),
                  child: Text(package.status.toUpperCase(), style: AppTextStyles.caption.copyWith(color: package.isActive ? Colors.green : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 10)),
                ),
                const Spacer(),
                Text('Rs. ${NumberFormat('#,##0').format(package.pricePerGuest)} / guest', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
              ]),
            ]),
          )),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) {
              if (value == 'manage') {
                onTap();
              } else if (value == 'edit') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEditPackageScreen(package: package)));
              } else if (value == 'delete') {
                _confirmDelete(context, package);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'manage',
                child: Text('Manage Package'),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TourPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tour Package?'),
        content: const Text('This package will no longer be available to travelers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Usually we'd do TourPackageRepository().deletePackage(package.id);
              // For safety and as requested by the prompt, soft-delete or inactive is better
              TourPackageRepository().updatePackageStatus(package.id, 'inactive');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
