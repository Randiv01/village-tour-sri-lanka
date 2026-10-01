import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

class AppSearchBar extends StatelessWidget {
  final String placeholder;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;

  const AppSearchBar({
    super.key,
    required this.placeholder,
    this.onTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.largeRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.largeRadius,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: AppRadius.largeRadius,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.search, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    placeholder,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onFilterTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.tune),
                      color: AppColors.primary,
                      onPressed: onFilterTap,
                      tooltip: 'Filter',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
