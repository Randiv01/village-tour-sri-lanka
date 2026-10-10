import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

class AppSearchBar extends StatelessWidget {
  final String placeholder;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({
    super.key,
    required this.placeholder,
    this.onTap,
    this.onFilterTap,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
          suffixIcon: onFilterTap != null
              ? IconButton(
                  icon: const Icon(Icons.tune),
                  color: AppColors.primary,
                  onPressed: onFilterTap,
                  tooltip: 'Filter',
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.largeRadius,
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.largeRadius,
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.largeRadius,
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
