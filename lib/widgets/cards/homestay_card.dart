import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class HomestayCard extends StatelessWidget {
  final String title;
  final String location;
  final String rating;
  final String reviews;
  final String price;
  final List<String> features;
  final String imagePath;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onViewDetailsTap;

  const HomestayCard({
    super.key,
    required this.title,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.features,
    required this.imagePath,
    this.onFavoriteTap,
    this.onViewDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  image: DecorationImage(
                    image: imagePath.startsWith('http')
                        ? NetworkImage(imagePath) as ImageProvider
                        : AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Rural Host',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onFavoriteTap ?? () {},
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.favorite_border,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.sectionHeading.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.tertiary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reviews,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: features
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.eco,
                                color: AppColors.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                f,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: AppTextStyles.sectionHeading.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          ' / night',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onViewDetailsTap ?? () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
