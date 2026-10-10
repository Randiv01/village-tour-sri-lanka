import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  bool _isFavorite = false;
  Position? _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentDestination = widget.destination;
    _pageController = PageController();
    _refreshDestination();
    _getCurrentLocation();
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

    bool isFav = false;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final favs = List<String>.from(userDoc.data()?['favoriteDestinations'] ?? []);
          isFav = favs.contains(_currentDestination.id);
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    try {
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to favorite.')));
      return;
    }
    final newFav = !_isFavorite;
    setState(() => _isFavorite = newFav);
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      if (newFav) {
        await userRef.update({'favoriteDestinations': FieldValue.arrayUnion([_currentDestination.id])});
      } else {
        await userRef.update({'favoriteDestinations': FieldValue.arrayRemove([_currentDestination.id])});
      }
    } catch (e) {
      setState(() => _isFavorite = !newFav);
    }
  }

  void _shareDestination() {
    // ignore: deprecated_member_use
    Share.share('Village Tour Sri Lanka\n\nDestination:\n${_currentDestination.name}\n\nLocation:\n${_currentDestination.locationName}\n\nExplore this destination on Village Tour Sri Lanka.');
  }

  Future<void> _openInGoogleMaps() async {
    final query = Uri.encodeComponent(_currentDestination.name);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
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
        backgroundColor: const Color(0xFFF8F6EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F6EF),
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primaryDark),
          centerTitle: true,
          title: Text(
            'Destination Details',
            style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : AppColors.primaryDark),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.primaryDark),
              onPressed: _shareDestination,
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(images),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      // Loading indicator if refreshing in background
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: LinearProgressIndicator(color: AppColors.primaryDark),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 280,
        color: AppColors.primaryDark.withValues(alpha: 0.1),
        width: double.infinity,
        child: const Center(child: Icon(Icons.terrain, size: 64, color: AppColors.textSecondary)),
      );
    }
    
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
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
                child: Hero(
                  tag: 'gallery_image_$index',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        CloudinaryUtils.getOptimizedUrl(
                          images[index],
                          width: 800,
                          height: 800,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
                      // Cinematic bottom gradient
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.42, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                      // Subtle top gradient
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.28],
                            colors: [
                              Colors.black.withValues(alpha: 0.40),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 22,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    if (_currentDestination.latitude == null ||
        _currentDestination.longitude == null) {
      return const SizedBox.shrink();
    }

    final destLocation = LatLng(_currentDestination.latitude!, _currentDestination.longitude!);
    LatLng? currentLoc = _currentPosition != null 
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null;

    final points = <LatLng>[destLocation];
    if (currentLoc != null) {
      points.add(currentLoc);
    }
    final bounds = points.length > 1 && points[0] != points[1]
        ? LatLngBounds.fromPoints(points)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location & Directions',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.softSecondarySurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: destLocation,
                    initialZoom: 13.0,
                    initialCameraFit: bounds != null
                        ? CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(40),
                          )
                        : null,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.villagetoursrilanka.app',
                      tileProvider: CachedTileProvider(),
                    ),
                    if (currentLoc != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [currentLoc, destLocation],
                            strokeWidth: 4.0,
                            color: AppColors.primary,
                            pattern: const StrokePattern.dotted(),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: destLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                        if (currentLoc != null)
                          Marker(
                            point: currentLoc,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'googleMapsBtn',
                        backgroundColor: Colors.white,
                        onPressed: _openInGoogleMaps,
                        child: const Icon(Icons.map, color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'fullscreenBtn',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfflineMapScreen(
                                selectedDestination: _currentDestination,
                                showOnlySelected: true,
                              ),
                            ),
                          );
                        },
                        child: const Icon(Icons.fullscreen, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
                if (currentLoc == null)
                   Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enable location services to see directions',
                              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
