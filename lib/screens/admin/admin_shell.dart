import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'admin_dashboard_screen.dart';
import 'destinations/manage_destinations_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const ManageDestinationsScreen(),
    // Placeholders for future modules
    const Center(child: Text('Homestays (Coming Soon)')),
    const Center(child: Text('Experiences (Coming Soon)')),
    const Center(child: Text('Bookings (Coming Soon)')),
    const Center(child: Text('Users (Coming Soon)')),
  ];



  @override
  Widget build(BuildContext context) {
    // Basic role check UI block could be added here if needed,
    // but actual routing protection should happen before arriving at AdminShell.

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Village Tour Sri Lanka',
              style: AppTextStyles.sectionHeading.copyWith(
                color: AppColors.primaryDark,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.of(context).pop(); // Back to traveler home
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      backgroundColor: AppColors.background,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  'Village Tour Sri Lanka',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Admin Portal',
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'CONTENT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _buildDrawerItem(Icons.place, 'Destinations', 1),
          _buildDrawerItem(Icons.house, 'Homestays', 2),
          _buildDrawerItem(Icons.explore, 'Experiences', 3),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'OPERATIONS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _buildDrawerItem(Icons.book, 'Bookings', 4),
          _buildDrawerItem(Icons.people, 'Users', 5),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        Navigator.pop(context); // Close drawer
      },
    );
  }
}
