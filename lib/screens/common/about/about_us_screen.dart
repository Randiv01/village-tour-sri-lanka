import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_radius.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: AppSpacing.xxl),
              _buildCommunityImpact(),
              const SizedBox(height: AppSpacing.xxl),
              _buildWhyGamgedara(),
              const SizedBox(height: AppSpacing.xxl),
              _buildCommunityKeepers(),
              const SizedBox(height: AppSpacing.xxl),
              _buildFooter(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              color: Colors.white,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.primaryDark,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: const Text(
        'About Us',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDark,
          fontFamily: 'PlayfairDisplay',
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF2E4F42), // Dark green background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VILLAGE TOUR SRI LANKA',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gamgedara Sanctuary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Born in Nilagama, Galewela in the cultural heartland near Sigiriya & Dambulla. We empower indigenous rural families, protect ancestral organic culinary arts, and provide travelers with genuine, living Sri Lankan hospitality.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _buildHeroTag(Icons.check_circle_outline, 'Eco-Certified 2018–2025'),
              const SizedBox(width: AppSpacing.sm),
              _buildHeroTag(Icons.star, '4.96 (128+ Reviews)', iconColor: const Color(0xFFFFC107)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTag(IconData icon, String label, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? const Color(0xFFFFCA28)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityImpact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Our Community Impact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
            Text(
              'Direct to Villages',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFD97706),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildImpactCard(
                icon: Icons.home_outlined,
                iconBg: const Color(0xFFFFF3E0),
                value: '30+',
                desc: 'Verified mud homestays hosted by local elders',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildImpactCard(
                icon: Icons.currency_rupee_outlined, // Closer to money/coin visual
                iconBg: const Color(0xFFFFF3E0),
                value: '85%',
                desc: 'Direct revenue kept by artisan families',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildImpactCard(
                icon: Icons.auto_awesome_outlined, // Sparkle/Plant
                iconBg: const Color(0xFFF3E5F5),
                value: '300+',
                desc: 'Ancient heirloom recipes safeguarded',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildImpactCard(
                icon: Icons.verified_user_outlined,
                iconBg: const Color(0xFFFFF3E0),
                value: '0%',
                desc: 'Hidden booking fees or exploitative middlemen',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImpactCard({
    required IconData icon,
    required Color iconBg,
    required String value,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFFEAE2CD), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFB45309)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              fontFamily: 'PlayfairDisplay',
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

  Widget _buildWhyGamgedara() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFFEAE2CD), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Gamgedara Was Created',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildWhyItem(
            icon: Icons.holiday_village_outlined,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFB45309),
            title: 'Authentic Mud Houses & Organic Farms',
            desc:
                'Every mud home is constructed with indigenous clay, wood, and illuk grass thatch, surrounded by 30-acre pesticide-free fruit orchards and scenic paddy tanks in Nilagama.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildWhyItem(
            icon: Icons.sentiment_satisfied_alt,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),
            title: 'Craftsmen & Cultural Keepers',
            desc:
                'Learn 3rd-century B.C. iron-smelting traditions with Mr. Wijesiri (blacksmith with 38+ yrs), experience handloom pit-weaving, and meet locals at the village Game Kopi Kade.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildWhyItem(
            icon: Icons.favorite_border,
            iconBg: const Color(0xFFF3E5F5), // Maybe yellow-ish? Let's use light yellow
            iconColor: const Color(0xFFF57F17),
            title: 'Rescued Working Cattle & Wildlife Sanctuaries',
            desc:
                'Our bullocks were gently rescued from slaughterhouses and now live peacefully on community pasture. Catamaran rides gently respect the eagles and fruit bats of Bats Lake.',
            overrideBgColor: const Color(0xFFFFF9C4),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    Color? overrideBgColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: overrideBgColor ?? iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityKeepers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Our Community Keepers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildKeeperCard(
          avatarLetters: 'BF',
          avatarColor: const Color(0xFF5D5737),
          name: 'Bandara & Family',
          tagLabel: 'Nilagama Elder',
          tagColor: const Color(0xFFF4F1E1),
          tagTextColor: const Color(0xFF2E4F42),
          desc: 'Superhost • 8 years preserving traditional mud tim...',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildKeeperCard(
          avatarLetters: 'KM',
          avatarColor: const Color(0xFF1B4332),
          name: 'Kusuma & Village Mothers',
          tagLabel: 'Culinary Guild',
          tagColor: const Color(0xFFE8F5E9),
          tagTextColor: const Color(0xFF2E4F42),
          desc: 'Master of clay-pot hearths & ancestral spice recip...',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildKeeperCard(
          avatarLetters: 'GF',
          avatarColor: const Color(0xFFB47228),
          name: 'Gimhani Fernando',
          tagLabel: 'Ambassador',
          tagColor: const Color(0xFFFFF3E0),
          tagTextColor: const Color(0xFFB45309),
          desc: 'Traveler community coordinator & cultural bridge',
        ),
      ],
    );
  }

  Widget _buildKeeperCard({
    required String avatarLetters,
    required Color avatarColor,
    required String name,
    required String tagLabel,
    required Color tagColor,
    required Color tagTextColor,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFFEAE2CD), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: avatarColor,
            child: Text(
              avatarLetters,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tagLabel,
                        style: TextStyle(
                          color: tagTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBE0), // Light beige box color
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Village Tour Sri Lanka Headquarters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFooterText('Location: ', 'Nilagama, Bambaragaswewa, Galewela, Sri Lanka'),
          const SizedBox(height: 6),
          _buildFooterText('Phone: ', '+94 71 422 6176 / +94 66 312 4564'),
          const SizedBox(height: 6),
          _buildFooterText('Email: ', 'info@villagetoursrilanka.com'),
          const SizedBox(height: 6),
          _buildFooterText('Web: ', 'www.villagetoursrilanka.com'),
          
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sri Lanka Tourism Reg. Certified',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              const Text(
                '© 2018–2025',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterText(String boldPart, String normalPart) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: boldPart,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          TextSpan(text: normalPart),
        ],
      ),
    );
  }
}
