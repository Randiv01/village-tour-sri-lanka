import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../models/destination.dart';
import '../../../../repositories/destination_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/cloudinary_utils.dart';
import '../destinations/destination_details_screen.dart';

class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
    );
  }
}

class OfflineMapScreen extends StatefulWidget {
  final Destination? selectedDestination;

  const OfflineMapScreen({super.key, this.selectedDestination});

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final DestinationRepository _repository = DestinationRepository();
  final MapController _mapController = MapController();

  List<Destination> _destinations = [];
  Destination? _selectedDest;
  bool _isLoading = true;
  Position? _currentPosition;
  bool _locationPermissionDenied = false;

  // Sri Lanka center coordinates
  final LatLng _sriLankaCenter = const LatLng(7.8731, 80.7718);
  final double _defaultZoom = 7.5;

  @override
  void initState() {
    super.initState();
    _selectedDest = widget.selectedDestination;
    _loadData();
    _getCurrentLocation();
  }

  Future<void> _loadData() async {
    try {
      final dests = await _repository.getActiveDestinationsStream().first;
      setState(() {
        _destinations = dests.where((d) => d.latitude != null && d.longitude != null).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationPermissionDenied = true);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _locationPermissionDenied = true);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _showAllDestinations() {
    setState(() {
      _selectedDest = null;
    });
    _mapController.move(_sriLankaCenter, _defaultZoom);
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }

  void _showCurrentLocation() {
    if (_locationPermissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is denied.')),
      );
      return;
    }
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
        14.0
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available yet.')),
      );
    }
  }

  void _showDestinationInfo(Destination dest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomInfoCard(dest),
    );
  }

  Widget _buildBottomInfoCard(Destination dest) {
    String imageUrl = '';
    if (dest.images.isNotEmpty) {
      imageUrl = dest.images.first.url;
    } else if (dest.imageUrl != null) {
      imageUrl = dest.imageUrl!;
    }
    imageUrl = CloudinaryUtils.getOptimizedUrl(imageUrl, width: 200, height: 200);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.terrain, size: 40),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.softSecondarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.terrain, color: AppColors.textSecondary),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest.name,
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dest.locationName,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            dest.shortDescription,
            style: AppTextStyles.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DestinationDetailsScreen(destination: dest),
                  ),
                );
              },
              child: const Text('View Destination'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offline Map'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        titleTextStyle: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.softSecondarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_done, 
                  size: 16, 
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'Offline Map Available',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.selectedDestination != null &&
                            widget.selectedDestination!.latitude != null &&
                            widget.selectedDestination!.longitude != null
                        ? LatLng(widget.selectedDestination!.latitude!, widget.selectedDestination!.longitude!)
                        : _sriLankaCenter,
                    initialZoom: widget.selectedDestination != null ? 12.0 : _defaultZoom,
                    minZoom: 6,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.villagetoursrilanka.app',
                      tileProvider: CachedTileProvider(),
                    ),
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: _destinations.map((dest) {
                        final isSelected = _selectedDest?.id == dest.id;
                        return Marker(
                          point: LatLng(dest.latitude!, dest.longitude!),
                          width: isSelected ? 50 : 40,
                          height: isSelected ? 50 : 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedDest = dest);
                              _showDestinationInfo(dest);
                            },
                            child: Icon(
                              Icons.location_on,
                              color: isSelected ? AppColors.primaryDark : AppColors.primary,
                              size: isSelected ? 50 : 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                // Map Controls
                Positioned(
                  right: 16,
                  bottom: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'btnShowAll',
                        backgroundColor: AppColors.surface,
                        onPressed: _showAllDestinations,
                        tooltip: 'Show All',
                        child: const Icon(Icons.map, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'btnLocation',
                        backgroundColor: AppColors.surface,
                        onPressed: _showCurrentLocation,
                        tooltip: 'Current Location',
                        child: const Icon(Icons.my_location, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'btnZoomIn',
                        backgroundColor: AppColors.surface,
                        onPressed: _zoomIn,
                        tooltip: 'Zoom In',
                        child: const Icon(Icons.add, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'btnZoomOut',
                        backgroundColor: AppColors.surface,
                        onPressed: _zoomOut,
                        tooltip: 'Zoom Out',
                        child: const Icon(Icons.remove, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
