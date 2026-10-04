import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleSelected;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECT ACCOUNT TYPE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(
                title: 'Traveler',
                description: 'Discover homestays & experiences',
                roleValue: 'traveler',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleOption(
                title: 'Host',
                description: 'Share your homestay',
                roleValue: 'host',
                icon: Icons.home_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleOption(
                title: 'Tour Guide',
                description: 'Lead local experiences',
                roleValue: 'guide',
                icon: Icons.group_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String description,
    required String roleValue,
    required IconData icon,
  }) {
    final bool isSelected = selectedRole == roleValue;

    return InkWell(
      onTap: () => onRoleSelected(roleValue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100, // Fixed height to keep them uniform
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
