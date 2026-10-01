import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_radius.dart';

class HomeFilterData {
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;
  final bool useLocation;
  final Position? locationPosition;

  HomeFilterData({
    this.checkIn,
    this.checkOut,
    this.adults = 1,
    this.children = 0,
    this.useLocation = false,
    this.locationPosition,
  });

  bool get hasAnyFilter =>
      checkIn != null ||
      checkOut != null ||
      adults > 1 ||
      children > 0 ||
      useLocation;

  int get totalGuests => adults + children;
}

class HomeFilterBottomSheet extends StatefulWidget {
  final HomeFilterData? initialData;

  const HomeFilterBottomSheet({super.key, this.initialData});

  @override
  State<HomeFilterBottomSheet> createState() => _HomeFilterBottomSheetState();
}

class _HomeFilterBottomSheetState extends State<HomeFilterBottomSheet> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 1;
  int _children = 0;
  bool _useLocation = false;
  Position? _position;

  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _checkIn = widget.initialData!.checkIn;
      _checkOut = widget.initialData!.checkOut;
      _adults = widget.initialData!.adults;
      _children = widget.initialData!.children;
      _useLocation = widget.initialData!.useLocation;
      _position = widget.initialData!.locationPosition;
    }
  }

  Future<void> _selectDates() async {
    final now = DateTime.now();
    final initialDateRange = _checkIn != null && _checkOut != null
        ? DateTimeRange(start: _checkIn!, end: _checkOut!)
        : null;

    final result = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _checkIn = result.start;
        _checkOut = result.end;
      });
    }
  }

  Future<void> _handleLocationTap() async {
    if (_useLocation) {
      setState(() {
        _useLocation = false;
        _position = null;
      });
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationError('Location permissions are permanently denied.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _useLocation = true;
          _position = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      _showLocationError('Failed to get location.');
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
      _useLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _checkIn = null;
      _checkOut = null;
      _adults = 1;
      _children = 0;
      _useLocation = false;
      _position = null;
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      HomeFilterData(
        checkIn: _checkIn,
        checkOut: _checkOut,
        adults: _adults,
        children: _children,
        useLocation: _useLocation,
        locationPosition: _position,
      ),
    );
  }

  bool get _hasAnyFilter =>
      _checkIn != null ||
      _checkOut != null ||
      _adults > 1 ||
      _children > 0 ||
      _useLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: AppTextStyles.sectionHeading),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Dates Section
            Text('Dates', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: AppColors.surface,
              borderRadius: AppRadius.cardRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _selectDates,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-in',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _checkIn != null
                                  ? DateFormat('dd MMM').format(_checkIn!)
                                  : 'Add date',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: AppColors.border),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-out',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _checkOut != null
                                  ? DateFormat('dd MMM').format(_checkOut!)
                                  : 'Add date',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Guests Section
            Text('Guests', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            _buildGuestRow(
              'Adults',
              _adults,
              () {
                if (_adults > 1) setState(() => _adults--);
              },
              () {
                setState(() => _adults++);
              },
              min: 1,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildGuestRow(
              'Children',
              _children,
              () {
                if (_children > 0) setState(() => _children--);
              },
              () {
                setState(() => _children++);
              },
              min: 0,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Location Section
            Text('Location', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: _useLocation
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: AppRadius.cardRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _handleLocationTap,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _useLocation
                          ? AppColors.primary
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: _useLocation
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _isLoadingLocation
                              ? 'Locating...'
                              : 'Use my location',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _useLocation
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: _useLocation
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_isLoadingLocation)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Actions
            Row(
              children: [
                TextButton(
                  onPressed: _hasAnyFilter ? _clearFilters : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(
                    'Clear',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _hasAnyFilter
                          ? AppColors.textSecondary
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _hasAnyFilter ? _applyFilters : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    foregroundColor: AppColors.surface,
                    disabledForegroundColor: AppColors.surface.withValues(
                      alpha: 0.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _hasAnyFilter
                          ? AppColors.surface
                          : AppColors.surface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
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

  Widget _buildGuestRow(
    String title,
    int count,
    VoidCallback onDecrease,
    VoidCallback onIncrease, {
    required int min,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bodyMedium),
        Row(
          children: [
            _buildStepperButton(Icons.remove, onDecrease, count > min),
            SizedBox(
              width: 40,
              child: Text(
                count.toString(),
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge,
              ),
            ),
            _buildStepperButton(Icons.add, onIncrease, true),
          ],
        ),
      ],
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onTap, bool enabled) {
    return Material(
      color: enabled ? AppColors.surface : AppColors.background,
      shape: CircleBorder(
        side: BorderSide(
          color: enabled
              ? AppColors.border
              : AppColors.border.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.textPrimary : AppColors.border,
          ),
        ),
      ),
    );
  }
}
