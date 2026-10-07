import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/app_bottom_navigation.dart';
import '../main/traveler_main_screen.dart';
import '../../common/auth/auth_guard.dart';

class CookeryExperienceScreen extends StatefulWidget {
  const CookeryExperienceScreen({super.key});

  @override
  State<CookeryExperienceScreen> createState() =>
      _CookeryExperienceScreenState();
}

class _CookeryExperienceScreenState extends State<CookeryExperienceScreen> {
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
          'Cookery Experience',
          style: AppTextStyles.screenHeading.copyWith(
            fontSize: 18,
          ),
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
                  Share.share('Check out the Traditional Village Cookery & Mudhouse Feast on Village Tour Sri Lanka!');
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
            _buildPreparedBySection(),
            const SizedBox(height: AppSpacing.xl),
            _buildCulinaryJourneySection(),
            const SizedBox(height: AppSpacing.xl),
            _buildInclusionsSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildWhatYoullPrepareSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildTimingsSection(),
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
                    builder: (context) => TravelerMainScreen(initialIndex: index),
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
      height: 260,
      decoration: BoxDecoration(
        borderRadius: AppRadius.largeRadius,
        image: const DecorationImage(
          image: AssetImage('assets/images/cookery/cookery_hero.png'), // Add suitable asset
          fit: BoxFit.cover,
        ),
        color: Colors.grey[800], // Fallback color
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
                        color: const Color(0xFFC47F46), // Matching UI image color
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'AUTHENTIC CULTURAL EXPERIENCE',
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
                        color: const Color(0xFF1E6B52), // Matching UI green
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Cook',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFFE8B255), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '2.5 Hours • Small Groups (Max 8)',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFFE8B255),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Traditional Village Cookery &\nMudhouse Feast',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.2,
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

  Widget _buildPreparedBySection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC47F46), width: 2),
                  color: const Color(0xFFEFE8DA),
                ),
                child: const Center(
                  child: Text(
                    'KM',
                    style: TextStyle(
                      color: Color(0xFF1E6B52),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1E6B52),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Led by Kusuma & Village Mothers',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Nilagama community keepers sharing ancestral culinary recipes passed down through 3 generations of hearth cooking.",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFC47F46),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nilagama Orchard Hearth',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E6B52),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'English & Sinhala Guided',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildCulinaryJourneySection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC47F46),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'The 4-Step Culinary Journey',
                    style: AppTextStyles.sectionHeading,
                  ),
                ],
              ),
              Text(
                'Hands-on',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFFC47F46),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          _buildJourneyStep(
            '1',
            'Herbal Welcome & Garden Harvest',
            'Sip fresh coriander tea, then stroll through the organic garden to handpick curry leaves, moringa, fiery kochchi chilies, and fresh lemongrass.',
            isLast: false,
          ),
          _buildJourneyStep(
            '2',
            'Miris Gala Grinding & Coconut Scraping',
            'Master the granite Miris Gala stone grinder to blend roasted curry powders, and scrape fresh coconuts using the traditional bench scraper (Hiramanaya).',
            isLast: false,
          ),
          _buildJourneyStep(
            '3',
            'Firewood Hearth & Clay Pot Cooking',
            'Simmer 5 traditional island curries in porous earthenware clay pots over cinnamon wood fires: baby jackfruit (Polos), rich dhal, lake fish, and gotu kola sambol.',
            isLast: false,
          ),
          _buildJourneyStep(
            '4',
            'Authentic Mudhouse Banana Leaf Feast',
            'Sit together on woven reed mats inside the cool clay mudhouse. Enjoy your self-cooked banquet on plantain leaves with steaming country red rice, crisp papadam, and buffalo curd drizzled with kitul treacle.',
            isLast: true,
            isLastOrange: true,
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep(
    String number,
    String title,
    String desc, {
    required bool isLast,
    bool isLastOrange = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isLastOrange ? const Color(0xFFC47F46) : const Color(0xFF2C5E47),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE5DBC7),
                  ),
                ),
              if (isLast)
                const SizedBox(height: 24),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
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

  Widget _buildInclusionsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE8DA), // Match background color from image
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC47F46)),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: Color(0xFFC47F46),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EXPERIENCE INCLUSIONS & OPTIONS',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C5E47),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              _buildInclusionChip('🌿', 'Vegan & Vegetarian Friendly', isGreen: true),
              _buildInclusionChip('📖', 'Secret Family Recipe Booklet'),
              _buildInclusionChip('🥘', 'All Farm Ingredients Included'),
              _buildInclusionChip('☕', 'Herbal Drinks & Dessert'),
              _buildInclusionChip('🏺', 'Traditional Mud Kitchen Setting'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionChip(String emoji, String text, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isGreen ? const Color(0xFFE0F2E9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGreen ? const Color(0xFF86D6AC) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: isGreen ? const Color(0xFF2C5E47) : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYoullPrepareSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC47F46),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "What You'll Prepare & Taste",
                    style: AppTextStyles.sectionHeading,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86D6AC)),
                ),
                child: Text(
                  '5 Curries Feast',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C5E47),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cook side-by-side using ancestral clay pots over slow cinnamon-wood fires. Feast together inside the cool clay mudhouse on fresh plantain leaves:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildFoodCard(
                  'Polos Jackfruit Curry',
                  'Tender young jackfruit simmered in heirloom roasted spices & thick coconut milk.',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildFoodCard(
                  'Lotus Stem & Dhal',
                  'Crisp lake lotus roots tempered with mustard seeds, turmeric & yellow lentils.',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildFoodCard(
                  'Miris Gala Pol Sambol',
                  'Fresh scraped coconut hand-ground on granite with kochchi chilies and lime.',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildFoodCard(
                  'Heirloom Red Rice Feast',
                  'Steamed organic paddy rice, crisp papadam & thick buffalo curd with kitul treacle.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: const Color(0xFFE5E2D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C5E47),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C5E47),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Experience Timings & Orchard Walk',
                  style: AppTextStyles.sectionHeading,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '2.5 – 3',
                    style: AppTextStyles.labelLarge,
                  ),
                  Text(
                    'Hours',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          _buildTimingCard(
            Icons.wb_sunny_outlined,
            const Color(0xFFC47F46),
            'Morning Masterclass & Midday Feast',
            '10:30 AM – 1:00 PM • Orchard harvest included',
            'Daily',
            isYellowBadge: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTimingCard(
            Icons.nature,
            const Color(0xFF2C5E47),
            'Sunset Cooking & Lantern Dinner',
            '4:30 PM – 7:00 PM • Twilight mudhouse ambiance',
            'Daily',
            isYellowBadge: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard(
    IconData icon,
    Color iconColor,
    String title,
    String timeStr,
    String badgeText, {
    required bool isYellowBadge,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: const Color(0xFFE5E2D9),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isYellowBadge ? const Color(0xFFFFF7E6) : const Color(0xFFE0F2E9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isYellowBadge ? const Color(0xFFFFD591) : const Color(0xFF86D6AC),
              ),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: isYellowBadge ? const Color(0xFF8C4A00) : const Color(0xFF1E6B52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
