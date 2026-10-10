import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bottom_navigation.dart';
import '../../../../widgets/common/app_side_menu.dart';
import '../home/traveler_home_screen.dart';
import '../destinations/explore_destinations_screen.dart';
import '../../common/auth/auth_guard.dart';
import '../bookings/traveler_bookings_screen.dart';
import '../profile/traveler_profile_screen.dart';

class TravelerMainScreen extends StatefulWidget {
  final int initialIndex;
  const TravelerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<TravelerMainScreen> createState() => _TravelerMainScreenState();
}

class _TravelerMainScreenState extends State<TravelerMainScreen> {
  late int _currentIndex;
  final GlobalKey<TravelerHomeScreenState> _homeKey =
      GlobalKey<TravelerHomeScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> get _pages => [
    TravelerHomeScreen(
      key: _homeKey,
      onProfileTap: () {
        setState(() {
          _currentIndex = 3;
        });
      },
      onSearchTap: () {
        setState(() {
          _currentIndex = 1;
        });
      },
    ),
    const ExploreDestinationsScreen(),
    const TravelerBookingsScreen(),
    TravelerProfileScreen(
      onBackTap: () {
        setState(() {
          _currentIndex = 0;
        });
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSideMenu(),
      body: _pages[_currentIndex],
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        exploreKey: TravelerHomeScreen.exploreNavKey,
        onTap: (index) {
          if (index == 0 && _currentIndex == 0) {
            _homeKey.currentState?.resetToHome();
            return;
          }

          if (index == 2 || index == 3) {
            AuthGuard.requireAuth(
              context: context,
              onAuthenticated: () {
                setState(() {
                  _currentIndex = index;
                });
              },
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
