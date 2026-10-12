import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

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
          _buildUsersAnalyticsCard(),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: [
              _buildCountCard(
                'Destinations',
                Icons.place,
                AppColors.primary,
                stream: FirebaseFirestore.instance
                    .collection('destinations')
                    .snapshots(),
              ),
              _buildCountCard(
                'Homestays',
                Icons.house,
                AppColors.secondary,
                stream: FirebaseFirestore.instance
                    .collection('homestays')
                    .snapshots(),
              ),
              _buildCountCard(
                'Tour Packages',
                Icons.tour,
                AppColors.tertiary,
                stream: FirebaseFirestore.instance
                    .collection('tour_packages')
                    .snapshots(),
              ),
              _buildCountCard(
                'Homestay Bookings',
                Icons.book_online,
                AppColors.textSecondary,
                stream: FirebaseFirestore.instance
                    .collection('homestay_bookings')
                    .snapshots(),
              ),
              _buildCountCard(
                'Package Bookings',
                Icons.collections_bookmark,
                AppColors.primary,
                stream: FirebaseFirestore.instance
                    .collection('guide_bookings')
                    .snapshots(),
              ),
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

  Widget _buildUsersAnalyticsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int travelers = 0;
        int hosts = 0;
        int guides = 0;
        int admins = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role'] as String?;
            if (role == 'traveler') {
              travelers++;
            } else if (role == 'host') {
              hosts++;
            } else if (role == 'guide') {
              guides++;
            } else if (role == 'admin') {
              admins++;
            }
          }
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: AppColors.primary, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Users Overview',
                    style: AppTextStyles.sectionHeading.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    snapshot.hasData ? '$total Total' : '...',
                    style: AppTextStyles.sectionHeading.copyWith(
                      color: AppColors.primary,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRoleStatItem(
                    'Travelers',
                    travelers,
                    Icons.person_outline,
                  ),
                  _buildRoleStatItem('Hosts', hosts, Icons.home_work_outlined),
                  _buildRoleStatItem('Guides', guides, Icons.explore_outlined),
                  _buildRoleStatItem(
                    'Admins',
                    admins,
                    Icons.admin_panel_settings_outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 28),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.primaryDark,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCountCard(
    String title,
    IconData icon,
    Color color, {
    Stream<QuerySnapshot>? stream,
    String placeholderCount = '0',
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              if (stream != null)
                StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length.toString()
                        : '...';
                    return Text(
                      count,
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 26,
                      ),
                    );
                  },
                )
              else
                Text(
                  placeholderCount,
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 26,
                  ),
                ),
            ],
          ),
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
