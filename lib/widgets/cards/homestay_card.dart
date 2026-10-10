import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../models/homestay.dart';

class HomestayCard extends StatefulWidget {
  final Homestay homestay;
  final VoidCallback? onViewDetailsTap;

  const HomestayCard({
    super.key,
    required this.homestay,
    this.onViewDetailsTap,
  });

  @override
  State<HomestayCard> createState() => _HomestayCardState();
}

class _HomestayCardState extends State<HomestayCard> {
  bool _isFavorite = false;
  int _reviewCount = 0;
  double _avgRating = 0.0;
  bool _loadedStats = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      // Load reviews
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('homestay_reviews')
          .where('homestayId', isEqualTo: widget.homestay.id)
          .get();

      double total = 0;
      for (final doc in reviewsSnap.docs) {
        total += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }
      final count = reviewsSnap.docs.length;
      final avg = count > 0 ? total / count : 0.0;

      // Load favorite state
      bool isFav = false;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);
        isFav = favorites.contains(widget.homestay.id);
      }

      if (mounted) {
        setState(() {
          _reviewCount = count;
          _avgRating = avg;
          _isFavorite = isFav;
          _loadedStats = true;
        });
      }
    } catch (e) {
      // Fail silently and use defaults if there's a permission error
      if (mounted) {
        setState(() {
          _loadedStats = true;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final newFav = !_isFavorite;

    setState(() => _isFavorite = newFav);

    if (newFav) {
      await userRef.update({'favorites': FieldValue.arrayUnion([widget.homestay.id])});
    } else {
      await userRef.update({'favorites': FieldValue.arrayRemove([widget.homestay.id])});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hs = widget.homestay;
    final imageUrl = hs.images.isNotEmpty ? hs.images.first : '';
    final ratingText = _loadedStats
        ? (_avgRating > 0 ? _avgRating.toStringAsFixed(1) : 'New')
        : '—';
    final reviewText = _loadedStats ? '($_reviewCount)' : '';
    final features = hs.amenities.take(2).toList();

    return GestureDetector(
      onTap: widget.onViewDetailsTap,
      child: Container(
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    color: AppColors.primaryDark.withValues(alpha: 0.1),
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: imageUrl.startsWith('http')
                                ? NetworkImage(imageUrl)
                                : AssetImage(imageUrl) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl.isEmpty
                      ? const Center(child: Icon(Icons.home, size: 48, color: AppColors.primaryDark))
                      : null,
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Rural Host',
                          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
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
                      onTap: _toggleFavorite,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : AppColors.textPrimary,
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
                          hs.title,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.tertiary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              ratingText,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reviewText,
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.secondary, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hs.location,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (features.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: features.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.eco, color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(f, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'Rs. ${hs.pricePerNight.toStringAsFixed(hs.pricePerNight % 1 == 0 ? 0 : 1)}',
                            style: AppTextStyles.sectionHeading.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            ' / night',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: widget.onViewDetailsTap ?? () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      ),
    );
  }
}
