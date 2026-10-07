import 'package:flutter/material.dart';

import '../../../../widgets/common/app_side_menu.dart';
import '../home/host_home_screen.dart';
import 'widgets/host_bottom_navigation.dart';

class HostMainScreen extends StatefulWidget {
  final int initialIndex;
  const HostMainScreen({super.key, this.initialIndex = 0});

  @override
  State<HostMainScreen> createState() => _HostMainScreenState();
}

class _HostMainScreenState extends State<HostMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const HostHomeScreen(),
    const Scaffold(body: Center(child: Text('Homestays Management Screen'))),
    const Scaffold(body: Center(child: Text('Bookings Management Screen'))),
    const Scaffold(body: Center(child: Text('Profile Settings Screen'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSideMenu(),
      body: _pages[_currentIndex],
      bottomNavigationBar: HostBottomNavigation(
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
