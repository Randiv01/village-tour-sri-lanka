import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
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

class _HomestayCardState extends State<HomestayCard>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  int _reviewCount = 0;
  double _avgRating = 0.0;
  bool _loadedStats = false;
  bool _isHostVerified = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
    _loadStats();
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
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

      bool isFav = false;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);
        isFav = favorites.contains(widget.homestay.id);
      }

      bool isHostVerified = false;
      try {
        final hostDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.homestay.hostId)
            .get();
        if (hostDoc.exists) {
          isHostVerified = hostDoc.data()?['isVerified'] == true ||
              hostDoc.data()?['verified'] == true;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _reviewCount = count;
          _avgRating = avg;
          _isFavorite = isFav;
          _isHostVerified = isHostVerified;
          _loadedStats = true;
        });
      }
    } catch (e) {
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

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    final newFav = !_isFavorite;
    setState(() => _isFavorite = newFav);

    _heartController.forward().then((_) => _heartController.reverse());

    if (newFav) {
      await userRef
          .update({'favorites': FieldValue.arrayUnion([widget.homestay.id])});
    } else {
      await userRef
          .update({'favorites': FieldValue.arrayRemove([widget.homestay.id])});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hs = widget.homestay;
    final imageUrl = hs.images.isNotEmpty ? hs.images.first : '';
    final ratingText = _loadedStats
        ? (_avgRating > 0 ? _avgRating.toStringAsFixed(1) : 'New')
        : '–';
    final features = hs.amenities.take(3).toList();
    final isVerified = _isHostVerified || hs.isVerified;
    final priceText =
        'Rs. ${hs.pricePerNight.toStringAsFixed(hs.pricePerNight % 1 == 0 ? 0 : 1)}';

    return GestureDetector(
      onTap: widget.onViewDetailsTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Cinematic Cover Image ─────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: Stack(
                children: [
                  // Image
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),

                  // Cinematic bottom gradient — pure black
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.42, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Subtle top vignette — pure black
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.28],
                          colors: [
                            Colors.black.withValues(alpha: 0.32),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Verified badge
                  if (isVerified)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _verifiedBadge(),
                    ),

                  // Favorite button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: ScaleTransition(
                        scale: _heartScale,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface.withValues(alpha: 0.18),
                            border: Border.all(
                              color:
                                  AppColors.surface.withValues(alpha: 0.30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.18),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavorite
                                ? AppColors.error
                                : AppColors.surface,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom overlay: title + location + rating
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hs.title,
                                  style: AppTextStyles.sectionHeading.copyWith(
                                    color: AppColors.surface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.primaryDark
                                            .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        color: AppColors.surface
                                            .withValues(alpha: 0.7),
                                        size: 13),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        hs.location,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.surface
                                              .withValues(alpha: 0.70),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _ratingPill(ratingText),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Bottom Card Content ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (features.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          features.map((f) => _amenityChip(f)).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Price + CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceText,
                            style: AppTextStyles.sectionHeading.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'per night',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      _viewDetailsButton(),
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

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _imagePlaceholder() {
    return Container(
      height: 220,
      color: AppColors.primaryDark.withValues(alpha: 0.12),
      child: const Center(
        child: Icon(Icons.home_rounded,
            size: 56, color: AppColors.primaryDark),
      ),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
          const SizedBox(width: 5),
          Text(
            'Verified',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingPill(String ratingText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: AppColors.tertiary, size: 14),
          const SizedBox(width: 4),
          Text(
            ratingText,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_loadedStats && _reviewCount > 0) ...[
            const SizedBox(width: 3),
            Text(
              '($_reviewCount)',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _amenityIcon(String amenity) {
    switch (amenity) {
      case 'Wi-Fi':            return Icons.wifi_rounded;
      case 'Free Parking':     return Icons.local_parking_rounded;
      case 'Breakfast':        return Icons.free_breakfast_rounded;
      case 'Private Bathroom': return Icons.bathtub_outlined;
      case 'Hot Water':        return Icons.water_drop_outlined;
      case 'Air Conditioning': return Icons.ac_unit_rounded;
      case 'Fan':              return Icons.wind_power_rounded;
      case 'Kitchen':          return Icons.kitchen_rounded;
      case 'Garden':           return Icons.yard_rounded;
      case 'TV':               return Icons.tv_rounded;
      default:                 return Icons.check_circle_outline_rounded;
    }
  }

  Widget _amenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_amenityIcon(label), color: AppColors.primary, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewDetailsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'View Details',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
