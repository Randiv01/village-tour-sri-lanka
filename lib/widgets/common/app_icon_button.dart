import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool hasBadge;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
