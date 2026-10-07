import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/tour_package.dart';
import '../../../repositories/tour_package_repository.dart';
import 'traveler_package_details_screen.dart';

class TravelerTourPackagesScreen extends StatefulWidget {
  const TravelerTourPackagesScreen({super.key});

  @override
  State<TravelerTourPackagesScreen> createState() => _TravelerTourPackagesScreenState();
}

class _TravelerTourPackagesScreenState extends State<TravelerTourPackagesScreen> {
  final TourPackageRepository _repo = TourPackageRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedDuration;
  String? _selectedPrice;
  final Map<String, String> _guideNames = {}; // guideId -> name
  final Map<String, String?> _guideImages = {}; // guideId -> imageUrl
  final Map<String, String?> _guidePhones = {}; // guideId -> phoneNumber
  
  List<TourPackage> _currentPackages = [];

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Future method to fetch guide details and update map
  Future<void> _fetchGuideDetails(String guideId) async {
    if (_guideNames.containsKey(guideId)) return;
    
    try {
      final doc = await _firestore.collection('users').doc(guideId).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _guideNames[guideId] = _capitalizeWords(doc.data()!['fullName'] ?? 'Unknown Guide');
            _guideImages[guideId] = doc.data()!['profileImageUrl'] ?? doc.data()!['profileImage'];
            _guidePhones[guideId] = doc.data()!['phoneNumber'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _guideNames[guideId] = 'Unknown Guide';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching guide $guideId: $e');
      if (mounted) {
        setState(() {
          _guideNames[guideId] = 'Unknown Guide';
        });
      }
    }
  }

  String _normalizeCategory(String? rawCategory) {
    if (rawCategory == null || rawCategory.trim().isEmpty) return 'Other Experience';
    if (TourPackage.packageCategories.contains(rawCategory.trim())) return rawCategory.trim();
    return 'Other Experience';
  }

  void _showFilterBottomSheet(BuildContext context) {
    final packages = _currentPackages;
    // Extract unique categories and locations
    final List<String> categories = ['All'];
    for (var cat in TourPackage.packageCategories) {
      if (packages.any((p) => _normalizeCategory(p.category) == cat)) {
        categories.add(cat);
      }
    }
    
    String tempCategory = _selectedCategory ?? 'All';
    String tempDuration = _selectedDuration ?? 'Any';
    String tempPrice = _selectedPrice ?? 'Any';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget buildSection(String title, List<String> options, String selectedValue, Function(String) onSelect) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
                      final isSelected = selectedValue == opt;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setModalState(() => onSelect(opt));
                        },
                        selectedColor: AppColors.primaryDark,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                        backgroundColor: AppColors.surface,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter Packages', style: AppTextStyles.sectionHeading),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    buildSection('Category', categories, tempCategory, (val) => tempCategory = val),
                    buildSection('Duration', ['Any', '1 Day', '2-3 Days', '4-7 Days', '8+ Days'], tempDuration, (val) => tempDuration = val),
                    buildSection('Price per Guest', ['Any', 'Under Rs. 5,000', 'Rs. 5,000 - 10,000', 'Rs. 10,000 - 20,000', 'Above Rs. 20,000'], tempPrice, (val) => tempPrice = val),
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _selectedDuration = tempDuration;
                            _selectedPrice = tempPrice;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = 'All';
                            _selectedDuration = 'Any';
                            _selectedPrice = 'Any';
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        centerTitle: true,
        title: Text(
          'Tour Packages',
          style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search village tours...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: Builder(
                  builder: (context) {
                    int activeFilters = 0;
                    if (_selectedCategory != null && _selectedCategory != 'All') activeFilters++;
                    if (_selectedDuration != null && _selectedDuration != 'Any') activeFilters++;
                    if (_selectedPrice != null && _selectedPrice != 'Any') activeFilters++;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list, color: AppColors.textSecondary),
                          onPressed: () {
                            _showFilterBottomSheet(context);
                          },
                        ),
                        if (activeFilters > 0)
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
                                activeFilters.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<TourPackage>>(
              stream: _repo.getActivePackagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Unable to load tour packages.'),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final packages = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _currentPackages != packages) {
                    _currentPackages = packages;
                  }
                });
                
                // Filter by search query and applied filters
                final filteredPackages = packages.where((p) {
                  // Text search
                  bool textMatch = true;
                  if (_searchQuery.isNotEmpty) {
                    final titleMatch = p.title.toLowerCase().contains(_searchQuery);
                    final locationMatch = p.location.toLowerCase().contains(_searchQuery);
                    final categoryMatch = (p.category ?? '').toLowerCase().contains(_searchQuery);
                    bool guideMatch = false;
                    if (_guideNames.containsKey(p.guideId)) {
                       guideMatch = _guideNames[p.guideId]!.toLowerCase().contains(_searchQuery);
                    }
                    textMatch = titleMatch || locationMatch || categoryMatch || guideMatch;
                  }
                  
                  // Category filter
                  bool categoryMatch = true;
                  if (_selectedCategory != null && _selectedCategory != 'All') {
                    categoryMatch = _normalizeCategory(p.category) == _selectedCategory;
                  }
                  
                  // Duration filter
                  bool durationMatch = true;
                  if (_selectedDuration != null && _selectedDuration != 'Any') {
                    if (_selectedDuration == '1 Day') {
                      durationMatch = p.durationDays == 1;
                    } else if (_selectedDuration == '2-3 Days') {
                      durationMatch = p.durationDays >= 2 && p.durationDays <= 3;
                    } else if (_selectedDuration == '4-7 Days') {
                      durationMatch = p.durationDays >= 4 && p.durationDays <= 7;
                    } else if (_selectedDuration == '8+ Days') {
                      durationMatch = p.durationDays >= 8;
                    }
                  }
                  
                  // Price filter
                  bool priceMatch = true;
                  if (_selectedPrice != null && _selectedPrice != 'Any') {
                    if (_selectedPrice == 'Under Rs. 5,000') {
                      priceMatch = p.pricePerGuest < 5000;
                    } else if (_selectedPrice == 'Rs. 5,000 - 10,000') {
                      priceMatch = p.pricePerGuest >= 5000 && p.pricePerGuest <= 10000;
                    } else if (_selectedPrice == 'Rs. 10,000 - 20,000') {
                      priceMatch = p.pricePerGuest >= 10000 && p.pricePerGuest <= 20000;
                    } else if (_selectedPrice == 'Above Rs. 20,000') {
                      priceMatch = p.pricePerGuest > 20000;
                    }
                  }

                  return textMatch && categoryMatch && durationMatch && priceMatch;
                }).toList();

                if (filteredPackages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _searchQuery.isEmpty ? 'No Tour Packages Available' : 'No matches found',
                          style: AppTextStyles.sectionHeading,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _searchQuery.isEmpty 
                            ? 'There are no active village tour packages available right now.'
                            : 'Try adjusting your search terms.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      child: Text(
                        '${filteredPackages.length} ${filteredPackages.length == 1 ? 'tour package' : 'tour packages'}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        itemCount: filteredPackages.length,
                        itemBuilder: (context, index) {
                          final package = filteredPackages[index];
                          
                          // Trigger guide details fetch if needed
                          _fetchGuideDetails(package.guideId);
                          
                          return _buildPackageCard(package);
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

  Widget _buildPackageCard(TourPackage package) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TravelerPackageDetailsScreen(packageId: package.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            SizedBox(
              height: 180,
              child: package.coverImageUrl != null && package.coverImageUrl!.isNotEmpty
                  ? Image.network(package.coverImageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primaryDark.withValues(alpha: 0.1),
                      child: const Icon(Icons.image, size: 64, color: AppColors.primary),
                    ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          package.title,
                          style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  if (package.category != null && package.category!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        package.category!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          package.location,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Details Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Duration & Guests
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${package.durationDays} Days • ${package.nights} Nights',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Up to ${package.maxGuests} Guests',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs. ${NumberFormat('#,##0').format(package.pricePerGuest)}',
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '/ guest',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Divider(height: 24, color: AppColors.border),
                  
                  // Footer: Guide info & CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            backgroundImage: _guideImages[package.guideId] != null && _guideImages[package.guideId]!.isNotEmpty
                                ? NetworkImage(_guideImages[package.guideId]!)
                                : null,
                            child: _guideImages[package.guideId] == null || _guideImages[package.guideId]!.isEmpty
                                ? const Icon(Icons.person, size: 16, color: AppColors.primaryDark)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guided by',
                                style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                              ),
                              Text(
                                _guideNames[package.guideId] ?? 'Loading...',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (_guidePhones[package.guideId] != null && _guidePhones[package.guideId]!.isNotEmpty)
                                GestureDetector(
                                  onTap: () async {
                                    final Uri url = Uri.parse('tel:${_guidePhones[package.guideId]}');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.phone, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          _guidePhones[package.guideId]!,
                                          style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TravelerPackageDetailsScreen(packageId: package.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('View Package'),
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
  }
}
