import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/contact_inquiry.dart';
import '../../../repositories/contact_inquiry_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import 'admin_inquiry_dialog.dart';

class AdminManageInquiriesScreen extends StatefulWidget {
  const AdminManageInquiriesScreen({super.key});

  @override
  State<AdminManageInquiriesScreen> createState() =>
      _AdminManageInquiriesScreenState();
}

class _AdminManageInquiriesScreenState extends State<AdminManageInquiriesScreen>
    with SingleTickerProviderStateMixin {
  final ContactInquiryRepository _repository = ContactInquiryRepository();
  late TabController _tabController;

  final List<String> _tabs = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
    'Closed',
  ];

  String _searchQuery = '';
  String _sortBy = 'Newest'; // Newest, Oldest, Name A-Z, Name Z-A

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade800;
      case 'in_progress':
        return Colors.blue.shade700;
      case 'resolved':
        return Colors.green.shade700;
      case 'closed':
        return Colors.grey.shade600;
      default:
        return AppColors.primary;
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  void _showAddEditDialog([ContactInquiry? inquiry]) {
    showDialog(
      context: context,
      builder: (ctx) => AdminInquiryDialog(inquiry: inquiry),
    );
  }

  Future<void> _changeStatus(ContactInquiry inquiry, String newStatus) async {
    try {
      await _repository.updateInquiryStatus(inquiry.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_formatStatusLabel(newStatus)}'),
          backgroundColor: _getStatusColor(newStatus),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteInquiry(ContactInquiry inquiry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Inquiry?'),
        content: Text(
          'Are you sure you want to permanently delete the inquiry from ${inquiry.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      try {
        await _repository.deleteInquiry(inquiry.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inquiry deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete inquiry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInquiryDetailsSheet(ContactInquiry inquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          inquiry.name,
                          style: AppTextStyles.screenHeading.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      _buildStatusBadge(inquiry.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Submitted on ${DateFormat('MMMM d, yyyy • h:mm a').format(inquiry.createdAt)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Contact Details Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.email_outlined,
                          'Email',
                          inquiry.email,
                        ),
                        if (inquiry.phoneNumber != null &&
                            inquiry.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            Icons.phone_outlined,
                            'Phone',
                            inquiry.phoneNumber!,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          Icons.public_outlined,
                          'Country',
                          inquiry.country,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Text('Message', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEAE2CD),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      inquiry.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryDark,
                        height: 1.5,
                      ),
                    ),
                  ),

                  if (inquiry.adminNotes != null &&
                      inquiry.adminNotes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Admin Notes', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 20,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              inquiry.adminNotes!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit / Notes'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddEditDialog(inquiry);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(
                            inquiry.status == 'resolved'
                                ? 'Mark Pending'
                                : 'Mark Resolved',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: inquiry.status == 'resolved'
                                ? Colors.amber.shade800
                                : Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _changeStatus(
                              inquiry,
                              inquiry.status == 'resolved'
                                  ? 'pending'
                                  : 'resolved',
                            );
                          },
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _formatStatusLabel(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSortSheet() {
    String tempSort = _sortBy;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                        'Sort Inquiries',
                        style: AppTextStyles.sectionHeading,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RadioGroup<String>(
                    groupValue: tempSort,
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => tempSort = val);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Newest', 'Oldest', 'Name A-Z', 'Name Z-A'].map((opt) {
                        return RadioListTile<String>(
                          title: Text(opt, style: AppTextStyles.bodyMedium),
                          value: opt,
                          activeColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() => tempSort = 'Newest');
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _sortBy = tempSort;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Inquiries Management',
            style: AppTextStyles.screenHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter & Add controls
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search inquiries...',
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
                  icon: const Icon(Icons.sort, color: AppColors.primary),
                  onPressed: _showFilterSortSheet,
                  tooltip: 'Sort Inquiries',
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
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Real-time List
          Expanded(
            child: StreamBuilder<List<ContactInquiry>>(
              stream: _repository.getInquiriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text('Error loading inquiries: ${snapshot.error}'),
                    ),
                  );
                }

                var list = snapshot.data ?? [];

                // Filter by Tab
                final currentTab = _tabs[_tabController.index];
                if (currentTab != 'All') {
                  list = list.where((inq) {
                    return inq.status.toLowerCase() ==
                        currentTab.toLowerCase().replaceAll(' ', '_');
                  }).toList();
                }

                // Filter by Search
                if (_searchQuery.trim().isNotEmpty) {
                  final q = _searchQuery.trim().toLowerCase();
                  list = list.where((inq) {
                    return inq.name.toLowerCase().contains(q) ||
                        inq.email.toLowerCase().contains(q) ||
                        inq.country.toLowerCase().contains(q) ||
                        inq.message.toLowerCase().contains(q) ||
                        (inq.phoneNumber != null &&
                            inq.phoneNumber!.toLowerCase().contains(q));
                  }).toList();
                }

                // Sorting
                if (_sortBy == 'Newest') {
                  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                } else if (_sortBy == 'Oldest') {
                  list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                } else if (_sortBy == 'Name A-Z') {
                  list.sort(
                    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                } else if (_sortBy == 'Name Z-A') {
                  list.sort(
                    (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
                  );
                }

                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            currentTab == 'All'
                                ? 'No contact inquiries found'
                                : 'No $currentTab inquiries',
                            style: AppTextStyles.sectionHeading.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try clearing your search query'
                                : 'When travelers submit the Contact Us form, they will appear here.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final inquiry = list[index];
                    return _buildInquiryCard(inquiry);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryCard(ContactInquiry inquiry) {
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showInquiryDetailsSheet(inquiry),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Status + Country + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildStatusBadge(inquiry.status),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inquiry.country,
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(inquiry.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Name
              Text(
                inquiry.name,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Contact row (Email & Phone)
              Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    inquiry.email,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (inquiry.phoneNumber != null &&
                      inquiry.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      inquiry.phoneNumber!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Message snippet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  inquiry.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryDark.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ),

              // Admin notes banner if present
              if (inquiry.adminNotes != null &&
                  inquiry.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 14,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Note: ${inquiry.adminNotes}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quick Status Change Popup Menu
                  PopupMenuButton<String>(
                    tooltip: 'Change Status',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 16,
                            color: _getStatusColor(inquiry.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(inquiry.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: _getStatusColor(inquiry.status),
                          ),
                        ],
                      ),
                    ),
                    onSelected: (newStatus) =>
                        _changeStatus(inquiry, newStatus),
                    itemBuilder: (ctx) => [
                      'pending',
                      'in_progress',
                      'resolved',
                      'closed',
                    ].map((status) {
                      final isCurrent = inquiry.status.toLowerCase() == status;
                      final col = _getStatusColor(status);
                      return PopupMenuItem<String>(
                        value: status,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatStatusLabel(status),
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent ? col : Colors.black87,
                              ),
                            ),
                            if (isCurrent) ...[
                              const Spacer(),
                              Icon(Icons.check, size: 16, color: col),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  // Edit and Delete
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.primary,
                        tooltip: 'Edit / Add Notes',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _showAddEditDialog(inquiry),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.error,
                        tooltip: 'Delete Inquiry',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _deleteInquiry(inquiry),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
