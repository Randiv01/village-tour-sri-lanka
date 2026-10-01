import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';

import 'package:intl/intl.dart';

import '../../../../widgets/common/app_search_bar.dart';
import '../../../../widgets/common/section_header.dart';
import '../../../../widgets/common/app_icon_button.dart';
import '../../../../widgets/cards/destination_card.dart';
import '../../../../widgets/cards/homestay_card.dart';
import 'widgets/home_filter_bottom_sheet.dart';
import '../../admin/admin_shell.dart';

class TravelerHomeScreen extends StatefulWidget {
  const TravelerHomeScreen({super.key});

  @override
  State<TravelerHomeScreen> createState() => _TravelerHomeScreenState();
}

class _TravelerHomeScreenState extends State<TravelerHomeScreen> {
  HomeFilterData? _filterData;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              _buildSearchBar(),
              _buildFiltersRow(),
              const SizedBox(height: AppSpacing.xl),
              _buildPopularDestinations(),
              const SizedBox(height: AppSpacing.xxl),
              _buildVillageExperienceBanner(),
              const SizedBox(height: AppSpacing.xxl),
              _buildRecommendedHomestays(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) {
              return AppIconButton(
                icon: Icons.menu,
                onTap: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          // Logo Area
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Village Tour Sri Lanka',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'A Better Local Experience',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Notification & Profile
          Row(
            children: [
              AppIconButton(
                icon: Icons.notifications_none,
                hasBadge: true,
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AdminShell()),
                  );
                },
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/onboarding/onboarding_01.png',
                      ), // Placeholder
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(Icons.person, color: Colors.transparent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AppSearchBar(
      placeholder: 'Search destinations, homestays...',
      onFilterTap: _openFilterSheet,
    );
  }

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<HomeFilterData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HomeFilterBottomSheet(initialData: _filterData),
    );

    if (result != null) {
      setState(() {
        _filterData = result.hasAnyFilter ? result : null;
      });
    }
  }

  Widget _buildFiltersRow() {
    if (_filterData == null || !_filterData!.hasAnyFilter) {
      return const SizedBox.shrink();
    }

    final filters = <Widget>[];

    if (_filterData!.checkIn != null && _filterData!.checkOut != null) {
      final inFormat = DateFormat('dd MMM').format(_filterData!.checkIn!);
      final outFormat = DateFormat('dd MMM').format(_filterData!.checkOut!);
      filters.add(
        _buildActiveFilterChip(
          Icons.calendar_today,
          '$inFormat–$outFormat',
          onRemove: () {
            setState(() {
              _filterData = HomeFilterData(
                adults: _filterData!.adults,
                children: _filterData!.children,
                useLocation: _filterData!.useLocation,
                locationPosition: _filterData!.locationPosition,
              );
              if (!_filterData!.hasAnyFilter) _filterData = null;
            });
          },
        ),
      );
    }

    if (_filterData!.adults > 1 || _filterData!.children > 0) {
      final text =
          '${_filterData!.totalGuests} Guest${_filterData!.totalGuests > 1 ? 's' : ''}';
      filters.add(
        _buildActiveFilterChip(
          Icons.people,
          text,
          onRemove: () {
            setState(() {
              _filterData = HomeFilterData(
                checkIn: _filterData!.checkIn,
                checkOut: _filterData!.checkOut,
                useLocation: _filterData!.useLocation,
                locationPosition: _filterData!.locationPosition,
              );
              if (!_filterData!.hasAnyFilter) _filterData = null;
            });
          },
        ),
      );
    }

    if (_filterData!.useLocation) {
      filters.add(
        _buildActiveFilterChip(
          Icons.location_on,
          'My Location',
          onRemove: () {
            setState(() {
              _filterData = HomeFilterData(
                checkIn: _filterData!.checkIn,
                checkOut: _filterData!.checkOut,
                adults: _filterData!.adults,
                children: _filterData!.children,
                useLocation: false,
                locationPosition: null,
              );
              if (!_filterData!.hasAnyFilter) _filterData = null;
            });
          },
        ),
      );
    }

    if (filters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          children: filters,
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(
    IconData icon,
    String label, {
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.close, size: 16, color: AppColors.primaryDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularDestinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Popular Destinations',
          subtitle: 'Explore ancient living heritage and nature',
          actionText: 'See all >',
          onActionTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: const [
              DestinationCard(
                title: 'Sigiriya',
                subtitle: 'Ancient Citadel',
                category: 'CITADEL',
                imagePath: 'assets/images/onboarding/onboarding_01.png',
              ),
              DestinationCard(
                title: 'Knuckles',
                subtitle: 'Central Range',
                category: 'HIGHLANDS',
                imagePath: 'assets/images/onboarding/onboarding_02.png',
              ),
              DestinationCard(
                title: 'Galewela',
                subtitle: 'Nilagama Village',
                category: 'SANCTUARY',
                imagePath: 'assets/images/onboarding/onboarding_03.png',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVillageExperienceBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'VILLAGE EXPERIENCE',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Authentic Traditions',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Living Crafts & River Safaris',
              style: AppTextStyles.sectionHeading.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Experience traditional blacksmithing, woodcarving, bullock cart rides across lotus lakes, and ancestral clay pot cooking lunch.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 44),
              ),
              child: Text(
                'Explore Experiences',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedHomestays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recommended Homestays',
          subtitle: 'Stay with verified rural artisan families',
        ),
        const SizedBox(height: AppSpacing.md),
        const HomestayCard(
          title: 'Nilagama Traditional Mud House',
          location: 'Nilagama, Bambaragaswewa, Galewela',
          rating: '4.9',
          reviews: '(48)',
          price: 'Rs. 3,500',
          features: ['Organic Farm & Bullock Cart', 'Catamaran Lake Ride'],
          imagePath: 'assets/images/onboarding/onboarding_01.png',
        ),
        const SizedBox(height: AppSpacing.lg),
        const HomestayCard(
          title: 'Lakeside Eco Sanctuary & Camp',
          location: 'Bats Lake, Galewela, Central Province',
          rating: '4.8',
          reviews: '(34)',
          price: 'Rs. 4,500',
          features: ['Camping', 'Bird Watching'],
          imagePath: 'assets/images/onboarding/onboarding_02.png',
        ),
      ],
    );
  }
}
