import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class DestinationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final String imageUrl;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const DestinationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.imageUrl,
    this.width,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show roughly 2.5 cards based on screen width if width is not provided
    final cardWidth = width ?? MediaQuery.of(context).size.width * 0.48;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: margin ?? const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface, // fallback color
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.softSecondarySurface,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.softSecondarySurface,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: AppColors.softSecondarySurface,
                  child: const Icon(
                    Icons.terrain,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty) ...[
                      Text(
                        category,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                    Text(
                      title,
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
