import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../services/cloudinary_service.dart';

class UpdateHomestayScreen extends StatefulWidget {
  final String homestayId;
  final Map<String, dynamic> homestayData;

  const UpdateHomestayScreen({
    super.key,
    required this.homestayId,
    required this.homestayData,
  });

  @override
  State<UpdateHomestayScreen> createState() => _UpdateHomestayScreenState();
}

class _UpdateHomestayScreenState extends State<UpdateHomestayScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _priceController;

  // Status
  late bool _isAvailable;

  // Images
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  List<String> _networkImages = [];
  final List<XFile> _selectedLocalImages = [];

  // Map Location
  LatLng? _selectedLocationPoint;
  final MapController _mapController = MapController();

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.homestayData['title'] ?? '');
    _priceController = TextEditingController(text: (widget.homestayData['pricePerNight'] ?? 0).toString());
    _isAvailable = (widget.homestayData['status'] ?? 'Active') == 'Active';
    
    if (widget.homestayData['images'] != null) {
      _networkImages = List<String>.from(widget.homestayData['images']);
    }
    
    if (widget.homestayData['latitude'] != null && widget.homestayData['longitude'] != null) {
      _selectedLocationPoint = LatLng(
        (widget.homestayData['latitude'] as num).toDouble(),
        (widget.homestayData['longitude'] as num).toDouble(),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          int totalImages = _networkImages.length + _selectedLocalImages.length;
          int remainingSlots = 10 - totalImages;
          if (images.length > remainingSlots) {
            _selectedLocalImages.addAll(images.take(remainingSlots));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can only upload up to 10 images in total.')),
            );
          } else {
            _selectedLocalImages.addAll(images);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeNetworkImage(int index) {
    setState(() {
      _networkImages.removeAt(index);
    });
  }

  void _removeLocalImage(int index) {
    setState(() {
      _selectedLocalImages.removeAt(index);
    });
  }

  Future<void> _deleteHomestay() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Homestay?'),
        content: const Text('Are you sure you want to permanently delete this homestay? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('homestays').doc(widget.homestayId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homestay deleted successfully!')),
        );
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _saveUpdates() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_networkImages.isEmpty && _selectedLocalImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please keep at least 1 image for your homestay.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Upload new locally picked Images to Cloudinary
      List<String> newlyUploadedUrls = [];
      for (var image in _selectedLocalImages) {
        final result = await _cloudinaryService.uploadImage(image);
        if (result != null) {
          newlyUploadedUrls.add(result.secureUrl);
        }
      }

      // Combine existing network images with new ones
      final allImageUrls = [..._networkImages, ...newlyUploadedUrls];

      // 2. Update document in Firestore
      final updates = {
        'title': _titleController.text.trim(),
        'pricePerNight': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'latitude': _selectedLocationPoint?.latitude,
        'longitude': _selectedLocationPoint?.longitude,
        'images': allImageUrls,
        'status': _isAvailable ? 'Active' : 'Inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('homestays').doc(widget.homestayId).update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homestay updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back to host home
      }
    } catch (e) {
      debugPrint('Error updating homestay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update homestay: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _buildAvailabilitySection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTitleSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildMapSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPriceSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildGallerySection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildGamgedaraTagSection(),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Delete Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _isSaving || _isDeleting ? null : _deleteHomestay,
                        icon: _isDeleting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                          : const Icon(Icons.delete_outline, color: AppColors.error),
                        label: const Text('Delete Homestay', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // padding for bottom button
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Sticky Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSaving || _isDeleting ? null : _saveUpdates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String shortId = widget.homestayId.length >= 4 
      ? widget.homestayId.substring(widget.homestayId.length - 4).toUpperCase() 
      : widget.homestayId.toUpperCase();

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              color: Colors.white,
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        children: [
          const Text(
            'VILLAGE SANCTUARY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'Update Homestay',
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.primaryDark,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        UnconstrainedBox(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F0ED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ID #$shortId',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Availability Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                      Text(
                        _isAvailable ? 'Currently AVAILABLE for booking' : 'Currently UNAVAILABLE for booking',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (val) {
              setState(() {
                _isAvailable = val;
              });
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryDark,
            inactiveTrackColor: AppColors.border,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Property Title'),
              Text('${_titleController.text.length} / 60 chars', style: const TextStyle(fontSize: 10, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hintText: 'e.g. Galewela Riverside Cottage',
            validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
            onChanged: (val) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Price per night (Rs.)'),
              const Text('Suggested: 3,200 - 4,000', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _priceController,
            hintText: '3,500',
            keyboardType: TextInputType.number,
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Rs.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F0ED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('/ night', style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Price is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pin Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
              if (_selectedLocationPoint != null)
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Tap on the map to update your homestay location', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocationPoint ?? const LatLng(7.8731, 80.7718),
                  initialZoom: _selectedLocationPoint != null ? 12.0 : 7.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedLocationPoint = point;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.villagetoursrilanka.app',
                  ),
                  if (_selectedLocationPoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocationPoint!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    int totalImages = _networkImages.length + _selectedLocalImages.length;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Uploaded Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
              Text('$totalImages photos uploaded', style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                // Network Images
                for (int i = 0; i < _networkImages.length; i++)
                  _buildImageCard(
                    imageProvider: NetworkImage(_networkImages[i]),
                    badgeText: i == 0 ? 'Cover' : 'Photo ${i + 1}',
                    onRemove: () => _removeNetworkImage(i),
                  ),
                
                // Local Picked Images
                for (int i = 0; i < _selectedLocalImages.length; i++)
                  _buildImageCard(
                    imageProvider: FileImage(File(_selectedLocalImages[i].path)),
                    badgeText: 'New',
                    onRemove: () => _removeLocalImage(i),
                  ),
                  
                // Add More Button
                if (totalImages < 10)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, color: AppColors.primaryDark, size: 24),
                          SizedBox(height: 8),
                          Text('Add photo', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard({
    required ImageProvider imageProvider,
    required String badgeText,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image(
              image: imageProvider,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.close, color: AppColors.error, size: 14),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamgedaraTagSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE0C5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEBE0C5)),
            ),
            child: const Icon(Icons.check, size: 16, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Gamgedara Heritage Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                    Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.secondary)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Includes clay stove breakfast, raw honey tea, and walk to the ancient lake bund.',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.normal),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
