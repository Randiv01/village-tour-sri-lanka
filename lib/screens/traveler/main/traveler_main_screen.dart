import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bottom_navigation.dart';
import '../../../../widgets/common/app_side_menu.dart';
import '../home/traveler_home_screen.dart';
import '../../common/auth/auth_guard.dart';

class TravelerMainScreen extends StatefulWidget {
  final int initialIndex;
  const TravelerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<TravelerMainScreen> createState() => _TravelerMainScreenState();
}

class _TravelerMainScreenState extends State<TravelerMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const TravelerHomeScreen(),
    const Scaffold(body: Center(child: Text('Explore Screen'))),
    const Scaffold(body: Center(child: Text('Bookings Screen'))),
    const Scaffold(body: Center(child: Text('Profile Screen'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSideMenu(),
      body: _pages[_currentIndex],
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
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
