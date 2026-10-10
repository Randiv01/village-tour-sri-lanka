import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_radius.dart';

class HomeFilterData {
  final String category; // 'All', 'Destinations', 'Homestays'
  final bool useLocation;
  final Position? locationPosition;

  // Advanced filters
  final String sortBy; // 'a-z', 'newest', 'oldest', 'price_asc', 'price_desc'
  final bool verifiedOnly;
  final List<String> amenities;
  final List<String> homestayTypes;

  HomeFilterData({
    this.category = 'All',
    this.useLocation = false,
    this.locationPosition,
    this.sortBy = 'newest',
    this.verifiedOnly = false,
    this.amenities = const [],
    this.homestayTypes = const [],
  });

  bool get hasAnyFilter =>
      useLocation ||
      category != 'All' ||
      sortBy != 'newest' ||
      verifiedOnly ||
      amenities.isNotEmpty ||
      homestayTypes.isNotEmpty;
}

class HomeFilterBottomSheet extends StatefulWidget {
  final HomeFilterData? initialData;

  const HomeFilterBottomSheet({super.key, this.initialData});

  @override
  State<HomeFilterBottomSheet> createState() => _HomeFilterBottomSheetState();
}

class _HomeFilterBottomSheetState extends State<HomeFilterBottomSheet> {
  bool _useLocation = false;
  Position? _position;
  String _category = 'All';

  String _sortBy = 'newest';
  bool _verifiedOnly = false;
  List<String> _amenities = [];
  List<String> _homestayTypes = [];

  bool _isLoadingLocation = false;

  final List<String> _allAmenities = [
    'Wi-Fi',
    'Free Parking',
    'Breakfast',
    'Private Bathroom',
    'Hot Water',
    'Air Conditioning',
    'Fan',
    'Kitchen',
    'Garden',
    'TV',
  ];

  final List<String> _allHomestayTypes = [
    'Villa',
    'Cabana',
    'Treehouse',
    'Shared Room',
    'Private Room',
    'Entire Home',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _useLocation = widget.initialData!.useLocation;
      _position = widget.initialData!.locationPosition;
      _category = widget.initialData!.category;
      _sortBy = widget.initialData!.sortBy;
      _verifiedOnly = widget.initialData!.verifiedOnly;
      _amenities = List.from(widget.initialData!.amenities);
      _homestayTypes = List.from(widget.initialData!.homestayTypes);
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
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      if (mounted) {
        setState(() {
          _useLocation = true;
          _position = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      _showLocationError('Failed to get location');
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _useLocation = false;
      _position = null;
      _category = 'All';
      _sortBy = 'newest';
      _verifiedOnly = false;
      _amenities.clear();
      _homestayTypes.clear();
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop(
      HomeFilterData(
        useLocation: _useLocation,
        locationPosition: _position,
        category: _category,
        sortBy: _sortBy,
        verifiedOnly: _verifiedOnly,
        amenities: _amenities,
        homestayTypes: _homestayTypes,
      ),
    );
  }

  bool get _hasAnyFilter =>
      _useLocation ||
      _category != 'All' ||
      _sortBy != 'newest' ||
      _verifiedOnly ||
      _amenities.isNotEmpty ||
      _homestayTypes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: AppTextStyles.sectionHeading),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection
                    Text('Category', style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChoiceChip('All', _category == 'All'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildChoiceChip(
                            'Destinations',
                            _category == 'Destinations',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildChoiceChip(
                            'Homestays',
                            _category == 'Homestays',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Sort By
                    Text('Sort By', style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildSortChip('Newest', 'newest'),
                        _buildSortChip('Oldest', 'oldest'),
                        _buildSortChip('A-Z', 'a-z'),
                        if (_category == 'All' || _category == 'Homestays') ...[
                          _buildSortChip('Price: Low to High', 'price_asc'),
                          _buildSortChip('Price: High to Low', 'price_desc'),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Only for Homestays or All
                    if (_category == 'All' || _category == 'Homestays') ...[
                      // Verified Hosts
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Only Verified Hosts',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Show stays with trusted, verified hosts',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          value: _verifiedOnly,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _verifiedOnly = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Homestay Types
                      Text('Property Type', style: AppTextStyles.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _allHomestayTypes.map((type) {
                          final isSelected = _homestayTypes.contains(type);
                          return FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _homestayTypes.add(type);
                                } else {
                                  _homestayTypes.remove(type);
                                }
                              });
                            },
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Amenities
                      Text('Amenities', style: AppTextStyles.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _allAmenities.map((amenity) {
                          final isSelected = _amenities.contains(amenity);
                          return FilterChip(
                            label: Text(amenity),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _amenities.add(amenity);
                                } else {
                                  _amenities.remove(amenity);
                                }
                              });
                            },
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions Footer
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
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
                      'Clear All',
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
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
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
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _category = label;
            // Clear incompatible filters if necessary
            if (label == 'Destinations') {
              if (_sortBy == 'price_asc' || _sortBy == 'price_desc') {
                _sortBy = 'newest';
              }
              _verifiedOnly = false;
              _amenities.clear();
              _homestayTypes.clear();
            }
          });
        }
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: isSelected ? AppColors.surface : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
          });
        }
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.secondary.withValues(alpha: 0.2),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.secondary : AppColors.border,
        ),
      ),
    );
  }
}
