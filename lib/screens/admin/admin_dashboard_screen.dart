import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: AppTextStyles.screenHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Welcome back, Admin',
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Manage content and operations across the Village Tour platform.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Text(
            'Quick Management',
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              _buildQuickCard('Destinations', Icons.place, AppColors.primary),
              _buildQuickCard('Homestays', Icons.house, AppColors.secondary),
              _buildQuickCard('Experiences', Icons.explore, AppColors.tertiary),
              _buildQuickCard('Bookings', Icons.book, AppColors.textSecondary),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),
          Text(
            'System Status',
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatusRow('Firebase Auth', true),
          const SizedBox(height: AppSpacing.sm),
          _buildStatusRow('Cloud Firestore', true),
          const SizedBox(height: AppSpacing.sm),
          _buildStatusRow('Cloudinary', true),
        ],
      ),
    );
  }

  Widget _buildQuickCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String service, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            service,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: AppTextStyles.caption.copyWith(
              color: isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
