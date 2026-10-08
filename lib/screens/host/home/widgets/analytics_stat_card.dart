import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_text_styles.dart';
import '../../../../../theme/app_spacing.dart';

class AnalyticsStatCard extends StatelessWidget {
  final IconData topIcon;
  final String title;
  final String value;
  final Widget? bottomWidget;
  final double width;

  const AnalyticsStatCard({
    super.key,
    required this.topIcon,
    required this.title,
    required this.value,
    this.bottomWidget,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softSecondarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(topIcon, size: 16, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 8),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}
