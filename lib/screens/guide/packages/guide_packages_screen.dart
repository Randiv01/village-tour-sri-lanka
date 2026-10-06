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

class GuidePackagesScreen extends StatelessWidget {
  const GuidePackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final repo = TourPackageRepository();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('My Packages', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEditPackageScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: AppRadius.pillRadius),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text('New', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<TourPackage>>(
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
                Text('Failed to load packages.', style: AppTextStyles.bodyLarge),
              ]),
            ));
          }
          final packages = snapshot.data ?? [];
          if (packages.isEmpty) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.explore_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: AppSpacing.lg),
                Text('No tour packages yet', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
                const SizedBox(height: AppSpacing.sm),
                Text('Create your first village tour package and start welcoming travelers.', textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Tour Package'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEditPackageScreen())),
                ),
              ]),
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: packages.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final pkg = packages[index];
              return _PackageListItem(
                package: pkg,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageManagementScreen(package: pkg))),
              );
            },
          );
        },
      ),
    );
  }
}

class _PackageListItem extends StatelessWidget {
  final TourPackage package; final VoidCallback onTap;
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
            child: SizedBox(width: 90, height: 90,
              child: package.coverImage != null && package.coverImage!.isNotEmpty
                  ? Image.network(package.coverImage!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.softSecondarySurface, child: const Icon(Icons.image, color: AppColors.textSecondary)))
                  : Container(color: AppColors.softSecondarySurface, child: Icon(Icons.explore, color: AppColors.primary.withValues(alpha: 0.3), size: 32)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(package.title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('D/N  |  Up to  Guests', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              if (package.location.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(package.location, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: package.isActive ? Colors.green.withValues(alpha: 0.1) : AppColors.softSecondarySurface, borderRadius: BorderRadius.circular(10)),
                  child: Text(package.isActive ? 'Active' : 'Inactive', style: AppTextStyles.caption.copyWith(color: package.isActive ? Colors.green : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
                const Spacer(),
                Text('Rs. ', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark)),
              ]),
            ]),
          )),
          const Padding(padding: EdgeInsets.only(right: AppSpacing.md), child: Icon(Icons.chevron_right, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
