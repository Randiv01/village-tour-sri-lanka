import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

class AppSideMenu extends StatelessWidget {
  const AppSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: AppRadius.smallRadius,
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Village Tour Sri Lanka',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'A Better Local Experience',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.secondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  // Profile Summary
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.background,
                          radius: 20,
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guest Traveler',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ayubowan, Explorer',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Active',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Main Menu Section
                  _buildSectionTitle('MAIN MENU', 'EXPERIENCES'),
                  _buildMenuItem(
                    Icons.restaurant,
                    'Buffet Lunch',
                    'Traditional Organic Farmer\'s Fea',
                    badge: 'Mud House',
                  ),
                  _buildMenuItem(
                    Icons.menu_book,
                    'Cookery Experience',
                    'Clay-pot curries & coconut grinding',
                  ),
                  _buildMenuItem(
                    Icons.explore,
                    'Tour Guides and Vehicles',
                    'Catamaran rides, Bullock cart & Crafts',
                  ),
                  _buildMenuItem(
                    Icons.image_outlined,
                    'Village Gallery',
                    'Lake flora, wildlife & visitor stories',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Support & Info Section
                  _buildSectionTitle('SUPPORT & INFO', ''),
                  _buildMenuItem(
                    Icons.phone_outlined,
                    'Contact Us',
                    '+94 71 422 6176 (WhatsApp)',
                  ),
                  _buildMenuItem(
                    Icons.info_outline,
                    'About Us',
                    'Preserving rural heritage & ecology',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Preferences Section
                  _buildSectionTitle('PREFERENCES', ''),
                  _buildMenuItem(
                    Icons.settings_outlined,
                    'Settings & Privacy',
                    '',
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'App Version',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softSecondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'v1.0.4',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.md,
        left: AppSpacing.xs,
        right: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                )
              : null,
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
