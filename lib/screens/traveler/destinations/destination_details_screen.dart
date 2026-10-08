import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../map/offline_map_screen.dart';
import '../../../../models/destination.dart';
import '../../../../repositories/destination_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/cloudinary_utils.dart';
import 'full_screen_gallery.dart';

class DestinationDetailsScreen extends StatefulWidget {
  final Destination destination;

  const DestinationDetailsScreen({super.key, required this.destination});

  @override
  State<DestinationDetailsScreen> createState() =>
      _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState extends State<DestinationDetailsScreen> {
  final DestinationRepository _repository = DestinationRepository();
  late Destination _currentDestination;
  late PageController _pageController;
  int _currentImageIndex = 0;
  bool _isLoading = false;
  bool _notFound = false;
  bool _notActive = false;

  @override
  void initState() {
    super.initState();
    _currentDestination = widget.destination;
    _pageController = PageController();
    _refreshDestination();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshDestination() async {
    setState(() => _isLoading = true);
    final freshDest = await _repository.getDestination(_currentDestination.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (freshDest == null) {
          _notFound = true;
        } else {
          _currentDestination = freshDest;
          if (!_currentDestination.isActive) {
            _notActive = true;
          }
        }
      });
    }
  }

  List<String> _getImages() {
    List<String> images = [];
    if (_currentDestination.images.isNotEmpty) {
      images = _currentDestination.images.map((img) => img.url).toList();
    } else if (_currentDestination.imageUrl != null &&
        _currentDestination.imageUrl!.isNotEmpty) {
      images = [_currentDestination.imageUrl!];
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    if (_notFound) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Destination not found.'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notActive) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('This destination is currently unavailable.'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Destinations'),
              ),
            ],
          ),
        ),
      );
    }

    final images = _getImages();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(images),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Loading indicator if refreshing in background
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.sm),
                              child: LinearProgressIndicator(),
                            ),

                          Text(
                            _currentDestination.name,
                            style: AppTextStyles.screenHeading.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _currentDestination.locationName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _currentDestination.shortDescription,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'About this place',
                            style: AppTextStyles.sectionHeading.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _currentDestination.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildLocationSection(),
                          const SizedBox(
                            height: AppSpacing.xxl * 2,
                          ), // Extra padding at bottom
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(List<String> images) {
    return SliverAppBar(
      expandedHeight: 350.0,
      pinned: true,
      backgroundColor:
          AppColors.background, // Match the safe area color when collapsed
      iconTheme: const IconThemeData(
        color: AppColors.primaryDark,
      ), // Dark icon when collapsed
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.7),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenGallery(
                        images: images,
                        initialIndex: _currentImageIndex,
                      ),
                    ),
                  );
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final optUrl = CloudinaryUtils.getOptimizedUrl(
                      images[index],
                      width: 800,
                      height: 800,
                    );
                    return Image.network(
                      optUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    );
                  },
                ),
              )
            else
              Container(
                color: AppColors.softSecondarySurface,
                child: const Icon(
                  Icons.terrain,
                  size: 80,
                  color: AppColors.textSecondary,
                ),
              ),

            // Navigation Arrows
            if (images.length > 1) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      if (_currentImageIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () {
                      if (_currentImageIndex < images.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],

            // Image Gradient Overlay for top buttons
            Positioned(
              top: 0,
              left: 0,
              right: 0,

              height: 100,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Image Counter
            if (images.length > 1)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Dots Indicator
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImageIndex == index ? 8 : 6,
                      height: _currentImageIndex == index ? 8 : 6,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    if (_currentDestination.latitude == null ||
        _currentDestination.longitude == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.softSecondarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Map placeholder
              const Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
              // Content overlay
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentDestination.locationName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        final lat = _currentDestination.latitude;
                        final lng = _currentDestination.longitude;
                        if (lat == null || lng == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Map location is not available for this destination.'),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OfflineMapScreen(
                              selectedDestination: _currentDestination,
                            ),
                          ),
                        );
                      },
                      child: const Text('View on Offline Map'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
