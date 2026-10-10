import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_bottom_navigation.dart';

import 'package:share_plus/share_plus.dart';

import '../main/traveler_main_screen.dart';
import '../../common/auth/auth_guard.dart';

class BuffetLunchExperienceScreen extends StatefulWidget {
  const BuffetLunchExperienceScreen({super.key});

  @override
  State<BuffetLunchExperienceScreen> createState() =>
      _BuffetLunchExperienceScreenState();
}

class _BuffetLunchExperienceScreenState
    extends State<BuffetLunchExperienceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          'Buffet Lunch Experience',
          style: AppTextStyles.screenHeading.copyWith(fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.share_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () {
                  // ignore: deprecated_member_use
                  Share.share(
                    'Check out the Traditional Village Buffet Lunch Experience on Village Tour Sri Lanka!',
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildSummarySection(),
            const SizedBox(height: AppSpacing.lg),
            _buildPreparedBySection(),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickHighlights(),
            const SizedBox(height: AppSpacing.xl),
            _buildWhatsIncludedSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildDiningExperienceSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildLocationSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildCulturalAddonInfo(),
            const SizedBox(height: AppSpacing.xl),
            _buildOptionalAddonFooter(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: -1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 2 || index == 3) {
            AuthGuard.requireAuth(
              context: context,
              onAuthenticated: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        TravelerMainScreen(initialIndex: index),
                  ),
                  (route) => false,
                );
              },
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => TravelerMainScreen(initialIndex: index),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: AppRadius.largeRadius,
        image: const DecorationImage(
          image: AssetImage(
            'assets/images/sign-in/auth_rural_landscape.png',
          ), // Fallback asset
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.largeRadius,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black26, Colors.black87],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'AUTHENTIC CULTURAL FEAST',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LOCALLY SOURCED',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.access_time,
                          '12:00 PM – 2:30 PM\nDaily',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildInfoChip(
                          Icons.eco_outlined,
                          'Banana Leaf\nDining',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Traditional Village Buffet Lunch',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tertiary, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Text(
      "Experience a traditional Sri Lankan village lunch prepared by local cooks using fresh, locally sourced ingredients and time-honoured cooking methods.",
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildPreparedBySection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryDark,
            radius: 24,
            backgroundImage: AssetImage(
              'assets/images/buffet_lunch/buffet_lunch_host.png',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Prepared by Nilagama Village Kitchen',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.verified,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Generations of local cooks prepare traditional village recipes using fresh local ingredients.",
                  style: AppTextStyles.caption.copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      color: AppColors.secondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nilagama Mudhouse',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Fresh Local Produce',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
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

  Widget _buildQuickHighlights() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHighlightItem(Icons.grass, '3 Rice Varieties', 'Heirloom / Red'),
        _buildHighlightItem(
          Icons.soup_kitchen,
          '5 Village Curries',
          'Clay pot cooked',
        ),
        _buildHighlightItem(
          Icons.set_meal,
          'Freshwater Fish',
          'Crispy pan fried',
        ),
        _buildHighlightItem(Icons.restaurant, 'Curd & Treacle', 'Wild Kithul'),
      ],
    );
  }

  Widget _buildHighlightItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsIncludedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT\'S INCLUDED',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Traditional Village Buffet Spread',
          style: AppTextStyles.sectionHeading,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildIncludedCard(
          '01',
          'Heirloom Village Rice Varieties',
          'Rathu Kakulu, steamed white rice and turmeric-infused village yellow rice, traditionally cooked in clay pots.',
          'Locally Sourced',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildIncludedCard(
          '02',
          'Five Hand-Harvested Curries',
          'Seasonal vegetables and traditional Sri Lankan curries prepared with fresh coconut milk and village spices.',
          'Farm Fresh',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildIncludedCard(
          '03',
          'Fried Freshwater Fish & Sambol',
          'Crispy freshwater fish with spicy green-chilli sambol and traditional accompaniments.',
          'Local Catch',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildIncludedCard(
          '04',
          'Traditional Village Sweets',
          'Buffalo curd, kithul treacle and seasonal Sri Lankan sweets.',
          'Sweet Finish',
        ),
      ],
    );
  }

  Widget _buildIncludedCard(
    String number,
    String title,
    String desc,
    String badge,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.softSecondarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: AppTextStyles.sectionHeading.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
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
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  desc,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiningExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE DINING EXPERIENCE',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How Your Village Lunch Unfolds',
          style: AppTextStyles.sectionHeading,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              _buildTimelineStep(
                '1',
                'Herbal Welcome',
                'Arrive after your village walk or local transfer and refresh with a welcome herbal tea and cool towel.',
                isLast: false,
              ),
              _buildTimelineStep(
                '2',
                'Clay Pot Unveiling',
                'Discover the aromas and traditional cooking methods behind each dish as the clay pots are opened.',
                isLast: false,
              ),
              _buildTimelineStep(
                '3',
                'Fresh Banana Leaf Feast',
                'Enjoy your meal in a relaxed village setting, served traditionally on a fresh banana leaf.',
                isLast: false,
              ),
              _buildTimelineStep(
                '4',
                'Curd, Treacle & Ginger Tea',
                'Finish with creamy buffalo curd, kithul treacle and Ceylon ginger tea.',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    String number,
    String title,
    String desc, {
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    desc,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOCATION & LOGISTICS',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dining Venue & Meeting Point',
              style: AppTextStyles.sectionHeading,
            ),
            Text(
              'Galewela',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nilagama Village Mudhouse Kitchen',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bambaragaswewa, Galewela\nCentral Cultural Triangle',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.smallRadius,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🛺', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Complimentary bullock-cart or tuk-tuk transfer is available from Galewela Junction for guests arriving via public bus or local transport.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCulturalAddonInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3ED),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cultural Add-on Experience',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buffet lunch can be reserved as an optional add-on when booking a participating Nilagama homestay, or included as part of the Village Tour day package.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryDark.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalAddonFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available as an optional add-on',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add this experience to your stay when booking an eligible homestay.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Rs. 1,800 / person',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
