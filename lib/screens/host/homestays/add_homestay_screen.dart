import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../services/cloudinary_service.dart';

class AddHomestayScreen extends StatefulWidget {
  const AddHomestayScreen({super.key});

  @override
  State<AddHomestayScreen> createState() => _AddHomestayScreenState();
}

class _AddHomestayScreenState extends State<AddHomestayScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController(text: '1');
  final _guestsController = TextEditingController(text: '2');
  final _descriptionController = TextEditingController();

  // Images
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Map Location
  LatLng? _selectedLocationPoint;
  final MapController _mapController = MapController();

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _guestsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70, // compress to save bandwidth
      );
      
      if (images.isNotEmpty) {
        setState(() {
          // Allow up to 10 images total
          int remainingSlots = 10 - _selectedImages.length;
          if (images.length > remainingSlots) {
            _selectedImages.addAll(images.take(remainingSlots));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can only upload up to 10 images in total.')),
            );
          } else {
            _selectedImages.addAll(images);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveAndPublish() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 image for your homestay.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to do this.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Upload Images to Cloudinary
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final result = await _cloudinaryService.uploadImage(image);
        if (result != null) {
          imageUrls.add(result.secureUrl);
        }
      }

      // 2. Save document to Firestore
      final homestayData = {
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _selectedLocationPoint?.latitude,
        'longitude': _selectedLocationPoint?.longitude,
        'pricePerNight': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'roomsCount': int.tryParse(_roomsController.text.trim()) ?? 1,
        'maxGuests': int.tryParse(_guestsController.text.trim()) ?? 1,
        'description': _descriptionController.text.trim(),
        'images': imageUrls,
        'hostId': user.uid,
        'status': 'Active', // Default status upon creation
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('homestays').add(homestayData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homestay published successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back to host home
      }
    } catch (e) {
      debugPrint('Error saving homestay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save homestay: $e'), backgroundColor: AppColors.error),
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
      backgroundColor: const Color(0xFFFBF9F6), // Slightly warm background matching image
      appBar: AppBar(
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
              'HOST REGISTRY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Add New Homestay',
              style: AppTextStyles.sectionHeading.copyWith(
                color: AppColors.primaryDark,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Drafts',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildMapSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildGallerySection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDescriptionSection(),
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
                  onPressed: _isSaving ? null : _saveAndPublish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Save and Publish Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ],
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
              const Text('Clear & authentic', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hintText: 'e.g. Galewela Riverside Cottage',
            validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Location / Village Name'),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _locationController,
            hintText: 'e.g. Nilagama, Galewela',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primaryDark),
            suffixIcon: const Icon(Icons.my_location, size: 18, color: AppColors.secondary),
            validator: (value) => value == null || value.isEmpty ? 'Location is required' : null,
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Price per night (Rs.)'),
              const Text('Village rate guideline', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
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
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('/ night', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Price is required' : null,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Extra fields for Rooms and Guests missing from mockup but needed for the Home Screen
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Rooms'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _roomsController,
                      hintText: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Req' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Max Guests'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _guestsController,
                      hintText: '2',
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Req' : null,
                    ),
                  ],
                ),
              ),
            ],
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
          const Text('Tap on the map to set your homestay location', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(7.8731, 80.7718),
                  initialZoom: 7.0,
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
              const Text('Homestay Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
              Row(
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text('${_selectedImages.length}/10 photos', style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (_selectedImages.isEmpty)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD3D8BE), style: BorderStyle.none), // We use dashed border visually if possible, but Container only supports solid. We'll use custom layout.
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tap to add village photos', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('Living room, veranda, organic garden', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (int i = 0; i < _selectedImages.length; i++)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImages[i].path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                          if (i == 0)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    
                    if (_selectedImages.length < 10)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                              SizedBox(height: 4),
                              Text('Add more', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
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
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF1E3), // Warm yellow tint
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.mic_none, size: 12, color: AppColors.secondary),
                    SizedBox(width: 4),
                    Text('Sinhala / English\nVoice', style: TextStyle(fontSize: 8, color: AppColors.secondary, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Traditional eco-mud sanctuary surrounded by lush 30-acre fruit orchards...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryDark),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
