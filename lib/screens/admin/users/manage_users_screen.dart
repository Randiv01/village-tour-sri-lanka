import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../models/user_model.dart';
import 'admin_crud_dialog.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              'User Management',
              style: AppTextStyles.screenHeading.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            isScrollable: true,
            tabs: [
              Tab(text: 'Travelers'),
              Tab(text: 'Hosts'),
              Tab(text: 'Guides'),
              Tab(text: 'Admins'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UsersListTab(role: 'traveler'),
            UsersListTab(role: 'host'),
            UsersListTab(role: 'guide'),
            UsersListTab(role: 'admin'),
          ],
        ),
      ),
    );
  }
}

class UsersListTab extends StatefulWidget {
  final String role;

  const UsersListTab({super.key, required this.role});

  @override
  State<UsersListTab> createState() => _UsersListTabState();
}

class _UsersListTabState extends State<UsersListTab> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive
  String _sortBy = 'Name A-Z'; // Name A-Z, Name Z-A, Newest, Oldest

  @override
  Widget build(BuildContext context) {
    String displayRole =
        widget.role.substring(0, 1).toUpperCase() + widget.role.substring(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopControls(displayRole),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: widget.role)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No ${displayRole}s found.'));
                }

                var users = snapshot.data!.docs
                    .map(
                      (doc) => UserModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList();

                // 1. Search filter
                if (_searchQuery.trim().isNotEmpty) {
                  final query = _searchQuery.trim().toLowerCase();
                  users = users.where((u) {
                    return u.fullName.toLowerCase().contains(query) ||
                        u.email.toLowerCase().contains(query) ||
                        u.phoneNumber.toLowerCase().contains(query);
                  }).toList();
                }

                // 2. Status filter
                if (_statusFilter == 'Active') {
                  users = users.where((u) => u.isActive).toList();
                } else if (_statusFilter == 'Inactive') {
                  users = users.where((u) => !u.isActive).toList();
                }

                // 3. Sorting
                if (_sortBy == 'Name A-Z') {
                  users.sort(
                    (a, b) => a.fullName.toLowerCase().compareTo(
                      b.fullName.toLowerCase(),
                    ),
                  );
                } else if (_sortBy == 'Name Z-A') {
                  users.sort(
                    (a, b) => b.fullName.toLowerCase().compareTo(
                      a.fullName.toLowerCase(),
                    ),
                  );
                } else if (_sortBy == 'Newest' || _sortBy == 'Oldest') {
                  users.sort((a, b) {
                    final dateA = a.createdAt ?? DateTime.now();
                    final dateB = b.createdAt ?? DateTime.now();
                    return _sortBy == 'Newest'
                        ? dateB.compareTo(dateA)
                        : dateA.compareTo(dateB);
                  });
                }

                if (users.isEmpty) {
                  return Center(
                    child: Text('No ${displayRole}s match your filters.'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        '${users.length} ${displayRole.toLowerCase()}${users.length == 1 ? '' : 's'}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final admin = users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar placeholder
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      color: admin.isActive
                                          ? AppColors.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.red.withValues(alpha: 0.1),
                                      child: Icon(
                                        _getRoleIcon(widget.role),
                                        size: 32,
                                        color: admin.isActive
                                            ? AppColors.primary
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          admin.fullName,
                                          style: AppTextStyles.labelLarge
                                              .copyWith(
                                                color: AppColors.primaryDark,
                                                fontSize: 16,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.email_outlined,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                admin.email,
                                                style: AppTextStyles.caption,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (admin.phoneNumber.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone_outlined,
                                                size: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  admin.phoneNumber,
                                                  style: AppTextStyles.caption,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            _buildBadge(
                                              admin.isActive
                                                  ? 'Active'
                                                  : 'Inactive',
                                              admin.isActive
                                                  ? Icons.check
                                                  : Icons.close,
                                              admin.isActive
                                                  ? Colors.green
                                                  : AppColors.error,
                                            ),
                                            _buildBadge(
                                              displayRole,
                                              _getRoleIcon(widget.role),
                                              AppColors.primary,
                                            ),
                                            if (admin.isVerified)
                                              _buildBadge(
                                                'Verified',
                                                Icons.verified,
                                                AppColors.primary,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const SizedBox(), // Placeholder for left side
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: AppColors.primary,
                                                  ),
                                                  onPressed: () =>
                                                      _showUserDialog(
                                                        context,
                                                        admin,
                                                      ),
                                                  tooltip: 'Edit',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                if (widget.role == 'host' ||
                                                    widget.role == 'guide')
                                                  IconButton(
                                                    icon: Icon(
                                                      admin.isVerified
                                                          ? Icons.verified
                                                          : Icons
                                                                .verified_outlined,
                                                      color: admin.isVerified
                                                          ? AppColors.primary
                                                          : AppColors
                                                                .textSecondary,
                                                    ),
                                                    onPressed: () =>
                                                        _toggleUserVerification(
                                                          admin,
                                                        ),
                                                    tooltip: admin.isVerified
                                                        ? 'Unverify'
                                                        : 'Verify',
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                  ),
                                                if (widget.role == 'host' ||
                                                    widget.role == 'guide')
                                                  const SizedBox(width: 4),
                                                IconButton(
                                                  icon: Icon(
                                                    admin.isActive
                                                        ? Icons
                                                              .visibility_off_outlined
                                                        : Icons
                                                              .visibility_outlined,
                                                    color: admin.isActive
                                                        ? AppColors
                                                              .textSecondary
                                                        : Colors.green,
                                                  ),
                                                  onPressed: () =>
                                                      _toggleUserStatus(admin),
                                                  tooltip: admin.isActive
                                                      ? 'Deactivate'
                                                      : 'Activate',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: AppColors.error,
                                                  ),
                                                  onPressed: () => _deleteUser(
                                                    context,
                                                    admin,
                                                  ),
                                                  tooltip: 'Delete',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(String displayRole) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ${displayRole}s...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.primary),
            onPressed: _showFilterSortSheet,
            tooltip: 'Filters & Sort',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _showUserDialog(context, null),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('+ Add'),
          ),
        ],
      ),
    );
  }

  void _showFilterSortSheet() {
    String tempStatus = _statusFilter;
    String tempSort = _sortBy;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bool hasChanges =
                tempStatus != _statusFilter || tempSort != _sortBy;
            final bool hasFilters =
                tempStatus != 'All' || tempSort != 'Name A-Z';

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters & Sort',
                        style: AppTextStyles.sectionHeading,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSheetDropdown(
                    'Status',
                    ['All', 'Active', 'Inactive'],
                    tempStatus,
                    (val) => setSheetState(() => tempStatus = val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSheetDropdown(
                    'Sort By',
                    ['Name A-Z', 'Name Z-A', 'Newest', 'Oldest'],
                    tempSort,
                    (val) => setSheetState(() => tempSort = val),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: hasFilters
                              ? () {
                                  setSheetState(() {
                                    tempStatus = 'All';
                                    tempSort = 'Name A-Z';
                                  });
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: hasFilters
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: hasFilters
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: hasChanges
                              ? () {
                                  setState(() {
                                    _statusFilter = tempStatus;
                                    _sortBy = tempSort;
                                  });
                                  Navigator.of(context).pop();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetDropdown(
    String label,
    List<String> options,
    String value,
    Function(String) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: options.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
                }).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'traveler':
        return Icons.person;
      case 'host':
        return Icons.home;
      case 'guide':
        return Icons.map;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  void _showUserDialog(BuildContext context, UserModel? user) {
    showDialog(
      context: context,
      builder: (context) => UserCrudDialog(user: user, role: widget.role),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isActive': !user.isActive},
      );
    } catch (e) {
      debugPrint('Error toggling ${widget.role} status: $e');
    }
  }

  Future<void> _toggleUserVerification(UserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isVerified': !user.isVerified},
      );
    } catch (e) {
      debugPrint('Error toggling ${widget.role} verification: $e');
    }
  }

  Future<void> _deleteUser(BuildContext context, UserModel user) async {
    String displayRole =
        widget.role.substring(0, 1).toUpperCase() + widget.role.substring(1);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $displayRole?'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
      } catch (e) {
        debugPrint('Error deleting ${widget.role}: $e');
      }
    }
  }
}
