import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/tour_package.dart';
import '../../../repositories/tour_package_repository.dart';
import 'create_edit_package_screen.dart';

class PackageManagementScreen extends StatefulWidget {
  final TourPackage package;
  const PackageManagementScreen({super.key, required this.package});

  @override
  State<PackageManagementScreen> createState() =>
      _PackageManagementScreenState();
}

class _PackageManagementScreenState extends State<PackageManagementScreen> {
  late TourPackage _package;
  final TourPackageRepository _repo = TourPackageRepository();
  bool _isLoading = false;
  int _currentImageIndex = 0;
  bool _showAllDates = false;

  @override
  void initState() {
    super.initState();
    _package = widget.package;
  }

  Future<void> _refresh() async {
    final updated = await _repo.getPackage(_package.id);
    if (updated != null && mounted) setState(() => _package = updated);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Delete Tour Package?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_package.title}"? This package will no longer be available to travelers.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final hasBookings = await _repo.hasBookings(_package.id, _package.guideId);
      if (hasBookings) {
        await _repo.updatePackageStatus(_package.id, 'inactive');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Package has bookings and was marked as inactive instead of deleted.',
              ),
              backgroundColor: AppColors.secondary,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _repo.deletePackage(_package.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tour package deleted successfully.'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _edit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditPackageScreen(package: _package),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }

  void _manageAvailability() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AvailabilityManagerSheet(
        package: _package,
        repo: _repo,
        onUpdated: () => _refresh(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final List<String> allImages = [];
    if (_package.coverImageUrl != null && _package.coverImageUrl!.isNotEmpty) {
      allImages.add(_package.coverImageUrl!);
    }
    for (var img in _package.galleryImages) {
      if (img.isNotEmpty && !allImages.contains(img)) {
        allImages.add(img);
      }
    }

    final sortedDates = List<DateTime>.from(_package.availabilityDates)..sort();
    final today = DateTime.now();
    final upcomingDates = sortedDates.where(
      (d) => !d.isBefore(DateTime(today.year, today.month, today.day)),
    ).toList();
    final pastDates = sortedDates.where(
      (d) => d.isBefore(DateTime(today.year, today.month, today.day)),
    ).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing Image Header ───────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: AppColors.background,
                onSelected: (val) {
                  if (val == 'edit') {
                    _edit();
                  } else if (val == 'availability') {
                    _manageAvailability();
                  } else if (val == 'delete') {
                    _delete();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text('Edit Package', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'availability',
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text('Manage Availability', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('Delete Package', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: allImages.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          itemCount: allImages.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImageIndex = i),
                          itemBuilder: (context, index) => Image.network(
                            allImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, err, stack) => Container(
                              color: AppColors.primaryDark,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                        // Dark gradient at bottom for legibility
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1} / ${allImages.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: AppColors.primaryDark,
                      child: const Icon(Icons.explore, size: 80, color: Colors.white24),
                    ),
            ),
          ),

          // ── Body content ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _package.title,
                          style: AppTextStyles.screenHeading
                              .copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _statusBadge(_package.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Category badge
                  if (_package.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _package.category!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.secondary),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),

                  // Price
                  Text(
                    'Rs. ${NumberFormat('#,##0').format(_package.pricePerGuest)} / guest',
                    style: AppTextStyles.sectionHeading
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Quick info grid
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _quickInfoTile(
                                Icons.timer_outlined,
                                'Duration',
                                '${_package.durationDays}D / ${_package.nights}N',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _quickInfoTile(
                                Icons.group_outlined,
                                'Max Guests',
                                '${_package.maxGuests} people',
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        Row(
                          children: [
                            Expanded(
                              child: _quickInfoTile(
                                Icons.directions_car_outlined,
                                'Vehicle',
                                _package.vehicleType.isNotEmpty
                                    ? _package.vehicleType
                                    : '—',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _quickInfoTile(
                                Icons.location_on_outlined,
                                'Location',
                                _package.location,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Available Dates ─────────────────────────────────
                  _sectionLabel(Icons.calendar_month_outlined, 'Available Dates'),
                  const SizedBox(height: AppSpacing.md),
                  _buildAvailabilitySection(upcomingDates, pastDates),
                  const SizedBox(height: AppSpacing.xl),

                  // Description
                  _sectionLabel(Icons.description_outlined, 'Description'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _package.description,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Places to visit
                  if (_package.placesToVisit.isNotEmpty) ...[
                    _sectionLabel(Icons.place_outlined, 'Places to Visit'),
                    const SizedBox(height: AppSpacing.sm),
                    ..._package.placesToVisit.map(
                      (e) => _listItem(e['title'] ?? '', e['description']),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Activities
                  if (_package.activities.isNotEmpty) ...[
                    _sectionLabel(Icons.hiking_outlined, 'Activities'),
                    const SizedBox(height: AppSpacing.sm),
                    ..._package.activities.map(
                      (e) => _listItem(e['title'] ?? '', e['description']),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Itinerary
                  if (_package.itinerary.isNotEmpty) ...[
                    _sectionLabel(Icons.route_outlined, 'Itinerary'),
                    const SizedBox(height: AppSpacing.sm),
                    ..._package.itinerary.asMap().entries.map(
                          (entry) => _itineraryItem(
                            entry.key + 1,
                            entry.value['title'] ?? '',
                            entry.value['description'],
                          ),
                        ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Inclusions & Exclusions
                  if (_package.includedItems.isNotEmpty ||
                      _package.excludedItems.isNotEmpty) ...[
                    _sectionLabel(
                        Icons.checklist_outlined, 'Inclusions & Exclusions'),
                    const SizedBox(height: AppSpacing.sm),
                    if (_package.includedItems.isNotEmpty) ...[
                      Text(
                        'Included',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      ..._package.includedItems.map(
                        (e) => _checkItem(e, true),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_package.excludedItems.isNotEmpty) ...[
                      Text(
                        'Excluded',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: 4),
                      ..._package.excludedItems.map(
                        (e) => _checkItem(e, false),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Meeting Point
                  if (_package.meetingPoint != null &&
                      _package.meetingPoint!.isNotEmpty) ...[
                    _sectionLabel(
                        Icons.meeting_room_outlined, 'Meeting Point'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _package.meetingPoint!,
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (_package.pickupNotes != null &&
                        _package.pickupNotes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _package.pickupNotes!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Action Buttons ──────────────────────────────────
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _edit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Package'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.inputButtonRadius,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _manageAvailability,
                          icon: const Icon(Icons.calendar_month_outlined,
                              size: 18, color: Colors.white),
                          label: const Text('Manage Dates'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      label: const Text('Delete Package'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.inputButtonRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection(
    List<DateTime> upcomingDates,
    List<DateTime> pastDates,
  ) {
    if (upcomingDates.isEmpty && pastDates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.softSecondarySurface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 36,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No Available Dates',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Add dates when this tour package can be booked.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _manageAvailability,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Available Date'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    final displayDates =
        _showAllDates ? upcomingDates : upcomingDates.take(4).toList();
    final hasMore = upcomingDates.length > 4 && !_showAllDates;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          if (upcomingDates.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No upcoming available dates.',
                style: AppTextStyles.bodySecondary,
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.upcoming_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Upcoming (${upcomingDates.length})',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ...displayDates.asMap().entries.map((entry) {
              final date = entry.value;
              return Column(
                children: [
                  const Divider(height: 1, indent: 12, endIndent: 12),
                  _dateTile(date),
                ],
              );
            }),
            if (hasMore)
              TextButton(
                onPressed: () => setState(() => _showAllDates = true),
                child: Text(
                  'View all ${upcomingDates.length} dates',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary),
                ),
              )
            else if (upcomingDates.length > 4 && _showAllDates)
              TextButton(
                onPressed: () => setState(() => _showAllDates = false),
                child: Text(
                  'Show less',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary),
                ),
              ),
          ],
          if (pastDates.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Past (${pastDates.length})',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ...pastDates.map(
              (date) => Column(
                children: [
                  const Divider(height: 1, indent: 12, endIndent: 12),
                  _dateTile(date, isPast: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  Widget _dateTile(DateTime date, {bool isPast = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 2),
      dense: true,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPast
              ? AppColors.softSecondarySurface
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('d').format(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isPast ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
            Text(
              DateFormat('MMM').format(date),
              style: TextStyle(
                fontSize: 9,
                color: isPast ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        DateFormat('EEEE, d MMMM yyyy').format(date),
        style: AppTextStyles.bodyMedium.copyWith(
          color: isPast ? AppColors.textSecondary : AppColors.textPrimary,
          decoration: isPast ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: isPast
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.softSecondarySurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Past',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            )
          : null,
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    Color bg;
    String label;
    switch (status) {
      case 'active':
        color = Colors.green;
        bg = Colors.green.withValues(alpha: 0.1);
        label = 'Active';
        break;
      case 'inactive':
        color = Colors.orange;
        bg = Colors.orange.withValues(alpha: 0.1);
        label = 'Inactive';
        break;
      default:
        color = AppColors.textSecondary;
        bg = AppColors.softSecondarySurface;
        label = 'Draft';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _quickInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.sm),
            Text(
              text,
              style:
                  AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark),
            ),
          ],
        ),
      );

  Widget _listItem(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itineraryItem(int day, String title, String? description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String text, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: isIncluded ? Colors.green : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

// ── Availability Manager Bottom Sheet ─────────────────────────────────────────

class _AvailabilityManagerSheet extends StatefulWidget {
  final TourPackage package;
  final TourPackageRepository repo;
  final VoidCallback onUpdated;

  const _AvailabilityManagerSheet({
    required this.package,
    required this.repo,
    required this.onUpdated,
  });

  @override
  State<_AvailabilityManagerSheet> createState() =>
      _AvailabilityManagerSheetState();
}

class _AvailabilityManagerSheetState
    extends State<_AvailabilityManagerSheet> {
  late List<DateTime> _dates;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dates = List<DateTime>.from(widget.package.availabilityDates)..sort();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime(today.year + 2, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Available Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
              surface: AppColors.surface,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final normalised = DateTime(picked.year, picked.month, picked.day);
    final alreadyExists = _dates.any(
      (d) =>
          d.year == normalised.year &&
          d.month == normalised.month &&
          d.day == normalised.day,
    );

    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This date is already selected.')),
        );
      }
      return;
    }

    setState(() {
      _dates.add(normalised);
      _dates.sort();
    });
  }

  void _removeDate(DateTime date) {
    setState(() {
      _dates.removeWhere(
        (d) =>
            d.year == date.year &&
            d.month == date.month &&
            d.day == date.day,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Build updated package with new dates
      final updatedPkg = TourPackage(
        id: widget.package.id,
        guideId: widget.package.guideId,
        title: widget.package.title,
        description: widget.package.description,
        category: widget.package.category,
        coverImageUrl: widget.package.coverImageUrl,
        galleryImages: widget.package.galleryImages,
        durationDays: widget.package.durationDays,
        nights: widget.package.nights,
        maxGuests: widget.package.maxGuests,
        pricePerGuest: widget.package.pricePerGuest,
        vehicleType: widget.package.vehicleType,
        location: widget.package.location,
        meetingPoint: widget.package.meetingPoint,
        pickupNotes: widget.package.pickupNotes,
        includedItems: widget.package.includedItems,
        excludedItems: widget.package.excludedItems,
        placesToVisit: widget.package.placesToVisit,
        activities: widget.package.activities,
        itinerary: widget.package.itinerary,
        availabilityDates: _dates,
        status: widget.package.status,
      );
      await widget.repo.updatePackage(updatedPkg);
      widget.onUpdated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Available dates updated successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    final upcoming = _dates
        .where((d) => !d.isBefore(todayMidnight))
        .toList();
    final past = _dates
        .where((d) => d.isBefore(todayMidnight))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Manage Availability',
                  style: AppTextStyles.sectionHeading
                      .copyWith(color: AppColors.primaryDark),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Add date button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined,
                        color: AppColors.primary),
                    label: Text(
                      'Add Available Date',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.inputButtonRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Upcoming dates
                if (upcoming.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.upcoming_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Upcoming Dates (${upcoming.length})',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: upcoming.asMap().entries.map((entry) {
                        final index = entry.key;
                        final date = entry.value;
                        return Column(
                          children: [
                            if (index > 0)
                              const Divider(
                                  height: 1, indent: 12, endIndent: 12),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md, vertical: 2),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('d').format(date),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM').format(date),
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                DateFormat('EEEE, d MMMM yyyy').format(date),
                                style: AppTextStyles.bodyMedium,
                              ),
                              trailing: GestureDetector(
                                onTap: () => _removeDate(date),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.error
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: AppColors.error),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Past dates (read-only, shown dimmed)
                if (past.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.history,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Past Dates (${past.length})',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.softSecondarySurface,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: past.asMap().entries.map((entry) {
                        final index = entry.key;
                        final date = entry.value;
                        return Column(
                          children: [
                            if (index > 0)
                              const Divider(
                                  height: 1, indent: 12, endIndent: 12),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md, vertical: 2),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.border
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('d').format(date),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM').format(date),
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                DateFormat('EEEE, d MMMM yyyy').format(date),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              trailing: GestureDetector(
                                onTap: () => _removeDate(date),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.error
                                        .withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (_dates.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.softSecondarySurface,
                      borderRadius: AppRadius.cardRadius,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 36,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No dates added yet.',
                          style: AppTextStyles.bodySecondary,
                        ),
                        Text(
                          'Tap the button above to add available dates.',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg +
                  MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: AppColors.primaryDark,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
