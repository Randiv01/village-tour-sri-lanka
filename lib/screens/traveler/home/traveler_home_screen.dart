import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';

import '../../../../widgets/common/app_search_bar.dart';
import '../../../../widgets/common/section_header.dart';
import '../../../../widgets/common/app_icon_button.dart';
import '../../../../widgets/cards/destination_card.dart';
import '../../../../widgets/cards/homestay_card.dart';
import 'widgets/home_filter_bottom_sheet.dart';
import '../../../../repositories/destination_repository.dart';
import '../../../../repositories/homestay_repository.dart';
import '../../../../services/auth_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/destination.dart';
import '../destinations/explore_destinations_screen.dart';
import '../destinations/destination_details_screen.dart';
import '../../common/auth/auth_guard.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../experiences/buffet_lunch_experience_screen.dart';
import '../experiences/cookery_experience_screen.dart';
import '../../common/homestays/homestay_details_screen.dart';
import '../../../../models/homestay.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TravelerHomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSearchTap;
  static final GlobalKey exploreNavKey = GlobalKey();

  const TravelerHomeScreen({super.key, this.onProfileTap, this.onSearchTap});

  @override
  State<TravelerHomeScreen> createState() => TravelerHomeScreenState();
}

class TravelerHomeScreenState extends State<TravelerHomeScreen>
    with TickerProviderStateMixin {
  HomeFilterData? _filterData;
  int _currentDestIndex = 0;
  late AnimationController _blinkController;
  late Stream<List<Destination>> _popularDestinationsStream;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final DestinationRepository _destinationRepository = DestinationRepository();
  final HomestayRepository _homestayRepository = HomestayRepository();

  void resetToHome() {
    FocusScope.of(context).unfocus();
    if (_searchQuery.isNotEmpty || _filterData != null) {
      setState(() {
        _searchController.clear();
        _searchQuery = '';
        _filterData = null;
      });
    }
  }

  // Walkthrough Keys
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _destinationsKey = GlobalKey();
  final GlobalKey _experienceKey = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _popularDestinationsStream = DestinationRepository()
        .getPopularActiveDestinationsStream();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _initTargets();
    _checkFirstTimeUser();
  }

  void _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_home_tutorial') ?? false;
    if (!hasSeenTutorial) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showTutorial();
        }
      });
      await prefs.setBool('has_seen_home_tutorial', true);
    }
  }

  void _showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primaryDark,
      skipWidget: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "SKIP",
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {},
      onClickTarget: (target) {},
      onSkip: () {
        return true;
      },
    )..show(context: context);
  }

  Widget _buildTutorialContent(String title, String description) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionHeading.copyWith(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              "Tap anywhere to continue",
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _initTargets() {
    targets.add(
      TargetFocus(
        identify: "search_bar",
        keyTarget: _searchKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                "Discover the Best Places",
                "Search for destinations, homestays, or experiences here. You can also apply filters!",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "profile",
        keyTarget: _profileKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                "Your Profile",
                "Manage your account, bookings, and preferences from here.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "menu",
        keyTarget: _menuKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                "App Menu",
                "Access more options, settings, and features from this menu.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "tour_packages",
        keyTarget: _experienceKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                "Tour Packages & Experiences",
                "Book unique local experiences like buffet lunches or cookery classes.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "explore",
        keyTarget: TravelerHomeScreen.exploreNavKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                "Explore Destinations",
                "Explore the most loved places in Sri Lanka. Tap here to see more!",
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _showProfileModal(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Profile',
                        style: AppTextStyles.sectionHeading.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        user?.email ?? 'Traveler',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final authService = AuthService();
                  await authService.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  'Sign Out',
                  style: AppTextStyles.buttonText.copyWith(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  bool get _isSearching =>
      _searchQuery.isNotEmpty ||
      (_filterData != null && _filterData!.hasAnyFilter);

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
              if (_isSearching)
                _buildSearchResults()
              else ...[
                const SizedBox(height: AppSpacing.xl),
                _buildPopularDestinations(),
                const SizedBox(height: AppSpacing.xxl),
                _buildVillageExperienceBanner(),
                const SizedBox(height: AppSpacing.xxl),
                _buildRecommendedHomestays(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Search Results', style: AppTextStyles.sectionHeading),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_filterData?.category == 'All' ||
            _filterData?.category == 'Destinations' ||
            _filterData == null)
          _buildDestinationsSearchStream(),
        if (_filterData?.category == 'All' ||
            _filterData?.category == 'Homestays' ||
            _filterData == null)
          _buildHomestaysSearchStream(),
      ],
    );
  }

  Widget _buildDestinationsSearchStream() {
    return StreamBuilder<List<Destination>>(
      stream: _destinationRepository.getActiveDestinationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var destinations = snapshot.data!.where((d) {
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            if (!(d.name.toLowerCase().contains(query) ||
                d.locationName.toLowerCase().contains(query))) {
              return false;
            }
          }
          return true;
        }).toList();

        if (_filterData != null) {
          if (_filterData!.sortBy == 'a-z') {
            destinations.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          } else if (_filterData!.sortBy == 'newest') {
            destinations.sort((a, b) => (b.createdAt).compareTo(a.createdAt));
          } else if (_filterData!.sortBy == 'oldest') {
            destinations.sort((a, b) => (a.createdAt).compareTo(b.createdAt));
          }
        }

        if (destinations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Destinations', style: AppTextStyles.labelLarge),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: SizedBox(
                    height: 220,
                    child: DestinationCard(
                      title: destination.name,
                      subtitle: destination.locationName,
                      category: 'Destination',
                      imageUrl: destination.images.isNotEmpty
                          ? destination.images.first.url
                          : '',
                      width: double.infinity,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DestinationDetailsScreen(
                              destination: destination,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  Widget _buildHomestaysSearchStream() {
    return StreamBuilder<List<Homestay>>(
      stream: _homestayRepository.getActiveHomestays(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var homestays = snapshot.data!.where((h) {
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            if (!(h.title.toLowerCase().contains(query) ||
                h.location.toLowerCase().contains(query))) {
              return false;
            }
          }

          if (_filterData != null) {
            if (_filterData!.verifiedOnly && !h.isVerified) return false;

            if (_filterData!.homestayTypes.isNotEmpty) {
              if (!_filterData!.homestayTypes.contains(h.propertyType)) {
                return false;
              }
            }

            if (_filterData!.amenities.isNotEmpty) {
              for (final amenity in _filterData!.amenities) {
                if (!h.amenities.contains(amenity)) return false;
              }
            }
          }

          return true;
        }).toList();

        if (_filterData != null) {
          if (_filterData!.sortBy == 'a-z') {
            homestays.sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            );
          } else if (_filterData!.sortBy == 'newest') {
            homestays.sort(
              (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                a.createdAt ?? DateTime.now(),
              ),
            );
          } else if (_filterData!.sortBy == 'oldest') {
            homestays.sort(
              (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
                b.createdAt ?? DateTime.now(),
              ),
            );
          } else if (_filterData!.sortBy == 'price_asc') {
            homestays.sort(
              (a, b) => a.pricePerNight.compareTo(b.pricePerNight),
            );
          } else if (_filterData!.sortBy == 'price_desc') {
            homestays.sort(
              (a, b) => b.pricePerNight.compareTo(a.pricePerNight),
            );
          }
        }

        if (homestays.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Homestays', style: AppTextStyles.labelLarge),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: homestays.length,
              itemBuilder: (context, index) {
                final homestay = homestays[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: HomestayCard(
                    homestay: homestay,
                    onViewDetailsTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HomestayDetailsScreen(homestayId: homestay.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
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
                key: _menuKey,
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
              _buildProfileIcon(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context) {
    return GestureDetector(
      key: _profileKey,
      onTap: () {
        AuthGuard.requireAuth(
          context: context,
          onAuthenticated: () {
            if (widget.onProfileTap != null) {
              widget.onProfileTap!();
            } else {
              _showProfileModal(context);
            }
          },
        );
      },
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          if (user == null) {
            // Guest State
            return _buildIconAvatar(null);
          }

          // Authenticated State - load profileImageUrl from Firestore
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, profileSnapshot) {
              String? profileImageUrl;
              if (profileSnapshot.hasData &&
                  profileSnapshot.data!.data() != null) {
                final data =
                    profileSnapshot.data!.data() as Map<String, dynamic>;
                profileImageUrl = data['profileImageUrl'] as String?;
              }
              return _buildIconAvatar(profileImageUrl);
            },
          );
        },
      ),
    );
  }

  Widget _buildIconAvatar(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      );
    }
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const Icon(Icons.person, color: AppColors.textSecondary),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      key: _searchKey,
      child: AppSearchBar(
        placeholder: 'Search destinations, homestays...',
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        onFilterTap: _openFilterSheet,
      ),
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

    void removeFilter(HomeFilterData newData) {
      setState(() {
        _filterData = newData;
        if (!_filterData!.hasAnyFilter) _filterData = null;
      });
    }

    if (_filterData!.category != 'All') {
      filters.add(
        _buildActiveFilterChip(
          Icons.category,
          _filterData!.category,
          onRemove: () {
            removeFilter(
              HomeFilterData(
                category: 'All',
                useLocation: _filterData!.useLocation,
                locationPosition: _filterData!.locationPosition,
                sortBy: _filterData!.sortBy,
                verifiedOnly: _filterData!.verifiedOnly,
                amenities: _filterData!.amenities,
                homestayTypes: _filterData!.homestayTypes,
              ),
            );
          },
        ),
      );
    }

    if (_filterData!.sortBy != 'newest') {
      String sortName = '';
      if (_filterData!.sortBy == 'oldest') sortName = 'Oldest';
      if (_filterData!.sortBy == 'a-z') sortName = 'A-Z';
      if (_filterData!.sortBy == 'price_asc') sortName = 'Price: Low-High';
      if (_filterData!.sortBy == 'price_desc') sortName = 'Price: High-Low';

      filters.add(
        _buildActiveFilterChip(
          Icons.sort,
          sortName,
          onRemove: () {
            removeFilter(
              HomeFilterData(
                category: _filterData!.category,
                useLocation: _filterData!.useLocation,
                locationPosition: _filterData!.locationPosition,
                sortBy: 'newest',
                verifiedOnly: _filterData!.verifiedOnly,
                amenities: _filterData!.amenities,
                homestayTypes: _filterData!.homestayTypes,
              ),
            );
          },
        ),
      );
    }

    if (_filterData!.verifiedOnly) {
      filters.add(
        _buildActiveFilterChip(
          Icons.verified,
          'Verified Only',
          onRemove: () {
            removeFilter(
              HomeFilterData(
                category: _filterData!.category,
                useLocation: _filterData!.useLocation,
                locationPosition: _filterData!.locationPosition,
                sortBy: _filterData!.sortBy,
                verifiedOnly: false,
                amenities: _filterData!.amenities,
                homestayTypes: _filterData!.homestayTypes,
              ),
            );
          },
        ),
      );
    }

    if (_filterData!.homestayTypes.isNotEmpty) {
      filters.add(
        _buildActiveFilterChip(
          Icons.house,
          '${_filterData!.homestayTypes.length} Types',
          onRemove: () {
            removeFilter(
              HomeFilterData(
                category: _filterData!.category,
                useLocation: _filterData!.useLocation,
                locationPosition: _filterData!.locationPosition,
                sortBy: _filterData!.sortBy,
                verifiedOnly: _filterData!.verifiedOnly,
                amenities: _filterData!.amenities,
                homestayTypes: const [],
              ),
            );
          },
        ),
      );
    }

    if (_filterData!.amenities.isNotEmpty) {
      filters.add(
        _buildActiveFilterChip(
          Icons.room_preferences,
          '${_filterData!.amenities.length} Amenities',
          onRemove: () {
            removeFilter(
              HomeFilterData(
                category: _filterData!.category,
                useLocation: _filterData!.useLocation,
                locationPosition: _filterData!.locationPosition,
                sortBy: _filterData!.sortBy,
                verifiedOnly: _filterData!.verifiedOnly,
                amenities: const [],
                homestayTypes: _filterData!.homestayTypes,
              ),
            );
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
            removeFilter(
              HomeFilterData(
                category: _filterData!.category,
                useLocation: false,
                locationPosition: null,
                sortBy: _filterData!.sortBy,
                verifiedOnly: _filterData!.verifiedOnly,
                amenities: _filterData!.amenities,
                homestayTypes: _filterData!.homestayTypes,
              ),
            );
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
    return Container(
      key: _destinationsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Popular Destinations',
            subtitle: 'Explore ancient living heritage and nature',
            actionText: 'See all >',
            onActionTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExploreDestinationsScreen(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FadeTransition(
                  opacity: _blinkController,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Swipe to explore',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<List<Destination>>(
            stream: _popularDestinationsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const Text('Unable to load destinations.'),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Container(
                        width:
                            (MediaQuery.of(context).size.width -
                                (AppSpacing.lg * 3)) /
                            2,
                        margin: EdgeInsets.only(
                          right: index == 2 ? 0 : AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softSecondarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                  ),
                );
              }

              final destinations = snapshot.data ?? [];

              if (destinations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    'No popular destinations yet.\nExplore more places coming soon.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        if (notification is ScrollUpdateNotification) {
                          final cardWidth =
                              (MediaQuery.of(context).size.width -
                                  (AppSpacing.lg * 3)) /
                              2;
                          final itemWidth = cardWidth + AppSpacing.lg;
                          int newIndex =
                              (notification.metrics.pixels / itemWidth).round();
                          if (newIndex < 0) {
                            newIndex = 0;
                          }
                          if (newIndex >= destinations.length) {
                            newIndex = destinations.length - 1;
                          }
                          if (newIndex != _currentDestIndex) {
                            setState(() {
                              _currentDestIndex = newIndex;
                            });
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: destinations.length,
                        itemBuilder: (context, index) {
                          final dest = destinations[index];
                          String imageUrl = '';
                          if (dest.images.isNotEmpty) {
                            imageUrl = dest.images.first.url;
                          } else if (dest.imageUrl != null) {
                            imageUrl = dest.imageUrl!;
                          }
                          final cardWidth =
                              (MediaQuery.of(context).size.width -
                                  (AppSpacing.lg * 3)) /
                              2;

                          return DestinationCard(
                            width: cardWidth,
                            margin: EdgeInsets.only(
                              right: index == destinations.length - 1
                                  ? 0
                                  : AppSpacing.lg,
                            ),
                            title: dest.name,
                            subtitle: dest.locationName,
                            category: 'DESTINATION',
                            imageUrl: imageUrl,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DestinationDetailsScreen(
                                        destination: dest,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(destinations.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentDestIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentDestIndex == index
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVillageExperienceBanner() {
    return Padding(
      key: _experienceKey,
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
              'Village Culinary Delights',
              style: AppTextStyles.sectionHeading.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Indulge in authentic Sri Lankan buffet feasts and master the art of clay-pot curries with our village mothers.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BuffetLunchExperienceScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(
                      'Buffet Lunch',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CookeryExperienceScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(
                      'Cookery',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
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
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('homestays')
              .where('status', isEqualTo: 'Active')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('Error loading homestays'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'No homestays available right now.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final hs = Homestay.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: HomestayCard(
                    homestay: hs,
                    onViewDetailsTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HomestayDetailsScreen(homestayId: doc.id),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
