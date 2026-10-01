import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bottom_navigation.dart';
import '../../../../widgets/common/app_side_menu.dart';
import '../home/traveler_home_screen.dart';

class TravelerMainScreen extends StatefulWidget {
  const TravelerMainScreen({super.key});

  @override
  State<TravelerMainScreen> createState() => _TravelerMainScreenState();
}

class _TravelerMainScreenState extends State<TravelerMainScreen> {
  int _currentIndex = 0;

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
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
