import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/tour_package.dart';
import '../../../repositories/tour_package_repository.dart';
import 'create_edit_package_screen.dart';

class PackageManagementScreen extends StatefulWidget {
  final TourPackage package;
  const PackageManagementScreen({super.key, required this.package});

  @override
  State<PackageManagementScreen> createState() => _PackageManagementScreenState();
}

class _PackageManagementScreenState extends State<PackageManagementScreen> {
  final _repo = TourPackageRepository();
  late TourPackage _package;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _package = widget.package;
  }

  Future<void> _toggleStatus() async {
    setState(() => _updating = true);
    try {
      final newStatus = _package.isActive ? 'inactive' : 'active';
      await _repo.updatePackageStatus(_package.id, newStatus);
      if (mounted) {
        setState(() {
          _package = _package.copyWith(status: newStatus);
          _updating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Package ${newStatus == "active" ? "activated" : "deactivated"}.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deletePackage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Package'),
        content: const Text('Are you sure you want to delete this package? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deletePackage(_package.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package deleted successfully.'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Manage Package',
          style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: AppSpacing.xl),
            Text('Package Actions', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            _actionTile(
              Icons.edit_outlined, 'Edit Package',
              'Modify package details and pricing',
              AppColors.primary,
              () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => CreateEditPackageScreen(package: _package)),
                );
                if (result == true) {
                  final updated = await _repo.getPackage(_package.id);
                  if (updated != null && mounted) setState(() => _package = updated);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _actionTile(
              _package.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
              _package.isActive ? 'Deactivate Package' : 'Activate Package',
              _package.isActive ? 'Hide from travelers' : 'Make visible to travelers',
              _package.isActive ? AppColors.secondary : Colors.green,
              _updating ? null : _toggleStatus,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Danger Zone', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            _actionTile(Icons.delete_outline, 'Delete Package', 'Permanently remove this package', AppColors.error, _deletePackage),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.cards)),
            child: _package.coverImage != null && _package.coverImage!.isNotEmpty
                ? Image.network(
                    _package.coverImage!,
                    height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _placeholder(),
                  )
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_package.title, style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _package.isActive ? Colors.green.withValues(alpha: 0.1) : AppColors.softSecondarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _package.isActive ? Colors.green : AppColors.border),
                      ),
                      child: Text(
                        _package.isActive ? 'Active' : 'Inactive',
                        style: AppTextStyles.caption.copyWith(color: _package.isActive ? Colors.green : AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${_package.durationDays} Days / ${_package.durationNights} Nights  •  Up to ${_package.maxGuests} Guests',
                  style: AppTextStyles.bodySecondary,
                ),
                if (_package.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_package.location, style: AppTextStyles.bodySecondary),
                ],
                if (_package.vehicleType.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_package.vehicleType, style: AppTextStyles.bodySecondary),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Rs. ${_package.price.toStringAsFixed(0)} / group',
                  style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                ),
                if (_package.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(_package.description, style: AppTextStyles.bodySecondary, maxLines: 4, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 180,
    color: AppColors.softSecondarySurface,
    child: Center(child: Icon(Icons.image_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.3))),
  );

  Widget _actionTile(IconData icon, String title, String subtitle, Color color, VoidCallback? onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge.copyWith(color: color.withValues(alpha: 0.9))),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
