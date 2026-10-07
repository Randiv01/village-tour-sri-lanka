import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../models/tour_package.dart';
import '../chat/traveler_chat_screen.dart';
import '../../../repositories/tour_package_repository.dart';

class TravelerPackageDetailsScreen extends StatefulWidget {
  final String packageId;
  const TravelerPackageDetailsScreen({super.key, required this.packageId});

  @override
  State<TravelerPackageDetailsScreen> createState() => _TravelerPackageDetailsScreenState();
}

class _TravelerPackageDetailsScreenState extends State<TravelerPackageDetailsScreen> {
  final TourPackageRepository _repo = TourPackageRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  TourPackage? _package;
  Map<String, dynamic>? _guideInfo;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pkg = await _repo.getPackage(widget.packageId);
      if (pkg != null) {
        if (mounted) setState(() => _package = pkg);
        
        try {
          final guideDoc = await _firestore.collection('users').doc(pkg.guideId).get();
          if (mounted && guideDoc.exists && guideDoc.data() != null) {
            setState(() {
              _guideInfo = guideDoc.data();
            });
          }
        } catch (guideErr) {
          debugPrint('Error fetching guide info: $guideErr');
          if (mounted) {
            setState(() {
              _guideInfo = {'fullName': 'Unknown Guide'};
            });
          }
        }
        
        if (mounted) setState(() => _isLoading = false);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading package: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleMessageGuide() {
    if (_package == null || _guideInfo == null) return;
    
    final guideId = _package!.guideId;
    final packageId = _package!.id;
    final packageTitle = _package!.title;
    final packagePrice = 'Rs. ${_package!.pricePerGuest.toStringAsFixed(0)}/day';
    final guideName = _guideInfo!['fullName'] ?? 'Guide';
    final guideImage = _guideInfo!['profileImage'] ?? _guideInfo!['profileImageUrl'] ?? '';
    final guideLanguages = _guideInfo!['languages'] != null ? (_guideInfo!['languages'] as List).join(' & ') : 'Sinhala & English';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelerChatScreen(
          guideId: guideId,
          guideName: guideName,
          guideImage: guideImage,
          guideLanguages: guideLanguages,
          packageId: packageId,
          packageTitle: packageTitle,
          packagePrice: packagePrice,
        ),
      ),
    );
  }

  void _handleBookTour() {
    // Future booking implementation hook
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking flow coming soon!')),
    );
  }

  void _openFullScreenGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGalleryScreen(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
    
    if (_package == null || !_package!.isActive) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primaryDark),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text('Currently unavailable', style: AppTextStyles.sectionHeading),
              const SizedBox(height: AppSpacing.sm),
              Text('This tour package is no longer available.', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    List<String> allImages = [];
    if (_package!.coverImageUrl != null && _package!.coverImageUrl!.isNotEmpty) {
      allImages.add(_package!.coverImageUrl!);
    }
    for (var img in _package!.galleryImages) {
      if (img.isNotEmpty && !allImages.contains(img)) {
        allImages.add(img);
      }
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primaryDark),
            onPressed: () {
              if (_package != null) {
                final shareText = 'Check out this village tour: ${_package!.title} in ${_package!.location}!\n\nDuration: ${_package!.durationDays} Days\nPrice: Rs. ${NumberFormat('#,##0').format(_package!.pricePerGuest)} per guest.\n\nDownload Village Tour Sri Lanka app to book this and many other authentic experiences.';
                // ignore: deprecated_member_use
                Share.share(shareText);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery
                  if (allImages.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: Stack(
                        children: [
                          PageView.builder(
                            itemCount: allImages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _openFullScreenGallery(context, allImages, index),
                                child: Image.network(
                                  allImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              );
                            },
                          ),
                          if (allImages.length > 1)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1} / ${allImages.length}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      height: 250,
                      color: AppColors.primaryDark.withValues(alpha: 0.1),
                      width: double.infinity,
                      child: const Icon(Icons.image, size: 64, color: AppColors.primaryDark),
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Category
                        Text(
                          _package!.title,
                          style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark, fontSize: 24),
                        ),
                        if (_package!.category != null && _package!.category!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _package!.category!,
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _package!.location,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Key Details Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn(Icons.timer, 'Duration', '${_package!.durationDays} Days, ${_package!.nights} Nights'),
                            _buildInfoColumn(Icons.group, 'Max Guests', 'Up to ${_package!.maxGuests}'),
                            _buildInfoColumn(Icons.payments, 'Price', 'Rs. ${NumberFormat('#,##0').format(_package!.pricePerGuest)}', isPrimary: true),
                          ],
                        ),
                        const Divider(height: 48, color: AppColors.border),
                        
                        // Guide Section
                        _buildSectionTitle('Guided by'),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              backgroundImage: _guideInfo != null && _guideInfo!['profileImage'] != null && _guideInfo!['profileImage'].toString().isNotEmpty
                                  ? NetworkImage(_guideInfo!['profileImage'])
                                  : (_guideInfo != null && _guideInfo!['profileImageUrl'] != null && _guideInfo!['profileImageUrl'].toString().isNotEmpty ? NetworkImage(_guideInfo!['profileImageUrl']) : null),
                              child: _guideInfo == null || ((_guideInfo!['profileImage'] == null || _guideInfo!['profileImage'].toString().isEmpty) && (_guideInfo!['profileImageUrl'] == null || _guideInfo!['profileImageUrl'].toString().isEmpty))
                                  ? const Icon(Icons.person, size: 32, color: AppColors.primaryDark)
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _guideInfo?['fullName'] != null ? _capitalizeWords(_guideInfo!['fullName']) : 'Tour Guide',
                                    style: AppTextStyles.labelLarge.copyWith(fontSize: 18),
                                  ),
                                  Text(
                                    'Tour Guide • ${_guideInfo?['location'] ?? _package!.location}',
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                  ),
                                  if (_guideInfo?['languages'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Speaks: ${(_guideInfo!['languages'] as List).join(", ")}',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ),
                                  if (_guideInfo?['phoneNumber'] != null && _guideInfo!['phoneNumber'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: GestureDetector(
                                        onTap: () async {
                                          final Uri url = Uri.parse('tel:${_guideInfo!['phoneNumber']}');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone, size: 14, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              _guideInfo!['phoneNumber'],
                                              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleMessageGuide,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message Guide'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                              side: const BorderSide(color: AppColors.primaryDark),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        
                        const Divider(height: 48, color: AppColors.border),
                        
                        // Description
                        _buildSectionTitle('About This Tour'),
                        Text(
                          _package!.description,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Places to Visit
                        if (_package!.placesToVisit.isNotEmpty) ...[
                          _buildSectionTitle('Places to Visit'),
                          ..._package!.placesToVisit.map((e) => _buildListItem(e['title'] ?? '', e['description'])),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        
                        // Activities
                        if (_package!.activities.isNotEmpty) ...[
                          _buildSectionTitle('Activities & Experiences'),
                          ..._package!.activities.map((e) => _buildListItem(e['title'] ?? '', e['description'])),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        
                        // Itinerary
                        if (_package!.itinerary.isNotEmpty) ...[
                          _buildSectionTitle('Itinerary'),
                          ..._package!.itinerary.map((e) => _buildListItem(e['title'] ?? '', e['description'], icon: Icons.schedule)),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        
                        // Included/Excluded
                        if (_package!.includedItems.isNotEmpty || _package!.excludedItems.isNotEmpty) ...[
                          _buildSectionTitle('What\'s Included'),
                          if (_package!.includedItems.isNotEmpty) ...[
                            ..._package!.includedItems.map((e) => _buildCheckItem(e, true)),
                          ],
                          if (_package!.excludedItems.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text('What\'s Not Included', style: AppTextStyles.labelLarge),
                            const SizedBox(height: AppSpacing.sm),
                            ..._package!.excludedItems.map((e) => _buildCheckItem(e, false)),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        
                        // Meeting / Pickup
                        if ((_package!.meetingPoint != null && _package!.meetingPoint!.isNotEmpty) ||
                            (_package!.pickupNotes != null && _package!.pickupNotes!.isNotEmpty)) ...[
                          _buildSectionTitle('Meeting & Pickup'),
                          if (_package!.meetingPoint != null && _package!.meetingPoint!.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.place, size: 20, color: AppColors.primaryDark),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_package!.meetingPoint!, style: AppTextStyles.bodyMedium)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          if (_package!.pickupNotes != null && _package!.pickupNotes!.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_package!.pickupNotes!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        
                        // Vehicle
                        if (_package!.vehicleType.isNotEmpty) ...[
                          _buildSectionTitle('Transport'),
                          Row(
                            children: [
                              const Icon(Icons.directions_car, size: 20, color: AppColors.primaryDark),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_package!.vehicleType, style: AppTextStyles.bodyMedium)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs. ${NumberFormat('#,##0').format(_package!.pricePerGuest)}',
                        style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark, fontSize: 18),
                      ),
                      Text('per guest', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _handleBookTour,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Book This Tour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: isPrimary ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: isPrimary ? AppColors.primaryDark : null)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(title, style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
    );
  }

  Widget _buildListItem(String title, String? subtitle, {IconData icon = Icons.circle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: icon == Icons.circle ? 6 : 2),
            child: Icon(icon, size: icon == Icons.circle ? 8 : 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isIncluded ? Icons.check_circle : Icons.cancel, size: 20, color: isIncluded ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class FullScreenGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGalleryScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenGalleryScreen> createState() => _FullScreenGalleryScreenState();
}

class _FullScreenGalleryScreenState extends State<FullScreenGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(
              widget.images[index],
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
