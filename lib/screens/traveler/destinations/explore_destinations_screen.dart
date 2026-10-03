import 'package:flutter/material.dart';

import '../../../../models/destination.dart';
import '../../../../repositories/destination_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/cloudinary_utils.dart';
import '../../../../widgets/cards/destination_card.dart';
import 'destination_details_screen.dart';

class ExploreDestinationsScreen extends StatefulWidget {
  const ExploreDestinationsScreen({super.key});

  @override
  State<ExploreDestinationsScreen> createState() =>
      _ExploreDestinationsScreenState();
}

class _ExploreDestinationsScreenState extends State<ExploreDestinationsScreen> {
  final DestinationRepository _repository = DestinationRepository();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedLocation;
  bool _popularOnly = false;
  String _sortBy = 'Recommended';

  int get _activeFilterCount {
    int count = 0;
    if (_selectedLocation != null && _selectedLocation != 'All Locations') {
      count++;
    }
    if (_popularOnly) count++;
    if (_sortBy != 'Recommended') count++;
    return count;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Destination> _filterAndSort(List<Destination> destinations) {
    var filtered = destinations.where((d) {
      if (!d.isActive) return false;

      if (_popularOnly && !d.isPopular) return false;

      if (_selectedLocation != null &&
          _selectedLocation != 'All Locations' &&
          d.locationName != _selectedLocation) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = d.name.toLowerCase().contains(q);
        final matchesLocation = d.locationName.toLowerCase().contains(q);
        final matchesDesc = d.shortDescription.toLowerCase().contains(q);
        if (!matchesName && !matchesLocation && !matchesDesc) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'A-Z') {
        return a.name.compareTo(b.name);
      } else if (_sortBy == 'Newest') {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return a.displayOrder.compareTo(b.displayOrder);
      }
    });

    return filtered;
  }

  void _showFilterSheet(List<Destination> allDestinations) {
    final locations = ['All Locations'];
    final uniqueLocs =
        allDestinations
            .map((d) => d.locationName)
            .where((l) => l.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    locations.addAll(uniqueLocs);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: AppTextStyles.sectionHeading),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Location', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLocation ?? 'All Locations',
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: locations.map((loc) {
                          return DropdownMenuItem(value: loc, child: Text(loc));
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => _selectedLocation = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Popularity', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: !_popularOnly,
                        onSelected: (val) {
                          if (val) setModalState(() => _popularOnly = false);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Popular Only'),
                        selected: _popularOnly,
                        onSelected: (val) {
                          if (val) setModalState(() => _popularOnly = true);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Sort By', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: ['Recommended', 'A-Z', 'Newest'].map((sort) {
                          return DropdownMenuItem(
                            value: sort,
                            child: Text(sort),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => _sortBy = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedLocation = 'All Locations';
                              _popularOnly = false;
                              _sortBy = 'Recommended';
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Apply to main screen
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
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
        title: const Text('Explore Destinations'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        titleTextStyle: AppTextStyles.sectionHeading.copyWith(
          color: AppColors.primaryDark,
        ),
      ),
      body: StreamBuilder<List<Destination>>(
        stream: _repository.getActiveDestinationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Couldn\'t load destinations\nCheck your connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDestinations = snapshot.data ?? [];
          if (allDestinations.isEmpty) {
            return const Center(
              child: Text(
                'No destinations available\nNew destinations will appear here soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final filteredDestinations = _filterAndSort(allDestinations);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search destinations...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune),
                          tooltip: 'Filter destinations',
                          onPressed: () => _showFilterSheet(allDestinations),
                        ),
                        if (_activeFilterCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Grid
              Expanded(
                child: filteredDestinations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No destinations found\nTry a different search or adjust your filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedLocation = null;
                                  _popularOnly = false;
                                  _sortBy = 'Recommended';
                                });
                              },
                              child: const Text('Clear Search'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: filteredDestinations.length,
                        itemBuilder: (context, index) {
                          final dest = filteredDestinations[index];
                          String imageUrl = '';
                          if (dest.images.isNotEmpty) {
                            imageUrl = dest.images.first.url;
                          } else if (dest.imageUrl != null) {
                            imageUrl = dest.imageUrl!;
                          }

                          imageUrl = CloudinaryUtils.getOptimizedUrl(
                            imageUrl,
                            width: 400,
                            height: 400,
                          );

                          return DestinationCard(
                            margin: EdgeInsets.zero,
                            title: dest.name,
                            subtitle: dest.locationName,
                            category: 'DESTINATION',
                            imageUrl: imageUrl,
                            width: double.infinity,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DestinationDetailsScreen(
                                        destination: dest,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
