import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../services/cloudinary_service.dart';
import '../../../../models/homestay.dart';
import '../../../../repositories/homestay_repository.dart';

class UpdateHomestayScreen extends StatefulWidget {
  final Homestay homestay;

  const UpdateHomestayScreen({super.key, required this.homestay});

  @override
  State<UpdateHomestayScreen> createState() => _UpdateHomestayScreenState();
}

class _UpdateHomestayScreenState extends State<UpdateHomestayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homestayRepo = HomestayRepository();
  
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _roomsController;
  late TextEditingController _guestsController;
  late TextEditingController _descriptionController;

  // Basic Info
  late String _propertyType;
  final List<String> _propertyTypes = ['Entire Homestay', 'Private Room', 'Shared Room'];

  // Amenities
  final List<String> _availableAmenities = [
    'Wi-Fi', 'Free Parking', 'Breakfast', 'Private Bathroom', 
    'Hot Water', 'Air Conditioning', 'Fan', 'Kitchen', 'Garden', 'TV'
  ];
  late List<String> _selectedAmenities;

  // House Rules
  final List<String> _availableRules = [
    'No Smoking', 'No Parties', 'Pets Allowed', 'Children Allowed'
  ];
  late List<String> _selectedRules;

  // Availability Days
  late Map<String, bool> _availableDays;

  // Unavailable Dates
  late List<DateTime> _unavailableDates;

  // Times
  late String _checkInTime;
  late String _checkOutTime;
  final List<String> _timeOptions = [
    '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM', '2:00 PM', 
    '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM'
  ];

  // Add-ons
  late List<Map<String, dynamic>> _addOns;

  // Status
  late bool _isAvailable;

  // Images
  final ImagePicker _picker = ImagePicker();
  late List<String> _networkImages;
  final List<XFile> _selectedLocalImages = [];
  final CloudinaryService _cloudinaryService = CloudinaryService();

  List<String> _networkImages = [];
  final List<XFile> _selectedLocalImages = [];

  // Map Location
  LatLng? _selectedLocationPoint;
  final MapController _mapController = MapController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.homestay;
    
    _titleController = TextEditingController(text: h.title);
    _locationController = TextEditingController(text: h.location);
    _priceController = TextEditingController(text: h.pricePerNight.toString());
    _roomsController = TextEditingController(text: h.rooms.toString());
    _guestsController = TextEditingController(text: h.maxGuests.toString());
    _descriptionController = TextEditingController(text: h.description);

    _propertyType = _propertyTypes.contains(h.propertyType) ? h.propertyType : _propertyTypes.first;
    _selectedAmenities = List.from(h.amenities);
    _selectedRules = List.from(h.houseRules);
    
    _availableDays = Map.from(h.availableDays);
    _unavailableDates = List.from(h.unavailableDates);
    
    _checkInTime = _timeOptions.contains(h.checkInTime) ? h.checkInTime : '2:00 PM';
    _checkOutTime = _timeOptions.contains(h.checkOutTime) ? h.checkOutTime : '11:00 AM';
    
    _addOns = List.from(h.optionalAddOns);
    
    _isAvailable = h.status == 'Active';
    _networkImages = List.from(h.images);

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
    _locationController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _guestsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
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

  void _removeNetworkImage(int index) => setState(() => _networkImages.removeAt(index));
  void _removeLocalImage(int index) => setState(() => _selectedLocalImages.removeAt(index));

  Future<void> _selectUnavailableDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (!_unavailableDates.any((d) => d.year == picked.year && d.month == picked.month && d.day == picked.day)) {
          _unavailableDates.add(picked);
          _unavailableDates.sort();
        }
      });
    }
  }

  void _showAddOnDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Optional Add-on'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g. Buffet Lunch)')),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (Rs.)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              if (title.isNotEmpty && price > 0) {
                setState(() {
                  _addOns.add({'title': title, 'price': price});
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
      List<String> newlyUploadedUrls = [];
      for (var image in _selectedLocalImages) {
        final result = await _cloudinaryService.uploadImage(image);
        if (result != null) {
          newlyUploadedUrls.add(result.secureUrl);
        }
      }

      final allImageUrls = [..._networkImages, ...newlyUploadedUrls];

      final updatedHomestay = Homestay(
        id: widget.homestay.id,
        hostId: widget.homestay.hostId,
        title: _titleController.text.trim(),
        propertyType: _propertyType,
        location: _locationController.text.trim(),
        latitude: _selectedLocationPoint?.latitude,
        longitude: _selectedLocationPoint?.longitude,
        description: _descriptionController.text.trim(),
        pricePerNight: double.tryParse(_priceController.text.trim()) ?? 0.0,
        rooms: int.tryParse(_roomsController.text.trim()) ?? 1,
        maxGuests: int.tryParse(_guestsController.text.trim()) ?? 1,
        images: allImageUrls,
        amenities: _selectedAmenities,
        houseRules: _selectedRules,
        availableDays: _availableDays,
        unavailableDates: _unavailableDates,
        checkInTime: _checkInTime,
        checkOutTime: _checkOutTime,
        optionalAddOns: _addOns,
        status: _isAvailable ? 'Active' : 'Inactive',
        createdAt: widget.homestay.createdAt,
      );

      await _homestayRepo.updateHomestay(updatedHomestay);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homestay updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border), color: Colors.white),
              child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Update Homestay',
          style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontSize: 18),
        ),
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
                    _buildAvailabilitySection(),
                    const SizedBox(height: AppSpacing.lg),
                  children: [
                    _buildSectionHeader('1. Basic Information'),
                    _buildBasicInfoSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildMapSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionHeader('2. Accommodation'),
                    _buildAccommodationSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('3. Amenities'),
                    _buildAmenitiesSection(),
                    
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('2. Accommodation'),
                    _buildAccommodationSection(),
                    
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('3. Amenities'),
                    _buildAmenitiesSection(),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('4. Gallery'),
                    _buildGallerySection(),
                    
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('5. Description'),
                    _buildDescriptionSection(),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('6. Booking Availability'),
                    _buildBookingAvailabilitySection(),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('7. Blackout Dates'),
                    _buildUnavailableDatesSection(),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('8. Check-in & Check-out'),
                    _buildTimesSection(),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('9. House Rules'),
                    _buildHouseRulesSection(),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('10. Optional Add-ons'),
                    _buildAddOnsSection(),

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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveUpdates,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark)),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border, width: 0.5)),
      child: child,
    );
  }

  Widget _buildAvailabilitySection() {
    return _buildSectionContainer(
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
                      const Text('Listing Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
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
            onChanged: (val) => setState(() => _isAvailable = val),
            activeThumbColor: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Property Title'),
          const SizedBox(height: 8),
          _buildTextField(controller: _titleController, hintText: 'e.g. Galewela Riverside Cottage', validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: AppSpacing.lg),
          _buildFieldLabel('Property Type'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _propertyType,
            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
            items: _propertyTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (val) => setState(() => _propertyType = val!),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFieldLabel('Location / Village Name'),
          const SizedBox(height: 8),
          _buildTextField(controller: _locationController, hintText: 'e.g. Nilagama, Galewela', prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primaryDark), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        ],
      ),
    );
  }

  Widget _buildAccommodationSection() {
    return _buildSectionContainer(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Price per night (Rs.)'),
              const Text('Village rate guideline', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(controller: _priceController, hintText: '3500', keyboardType: TextInputType.number, prefixIcon: const Padding(padding: EdgeInsets.all(12.0), child: Text('Rs.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark))), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Rooms'),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _roomsController, hintText: '1', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Req' : null),
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
                    _buildTextField(controller: _guestsController, hintText: '2', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Req' : null),
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

  Widget _buildAmenitiesSection() {
    return _buildSectionContainer(
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _availableAmenities.map((amenity) {
          final isSelected = _selectedAmenities.contains(amenity);
          return FilterChip(
            label: Text(amenity),
            selected: isSelected,
            onSelected: (val) => setState(() { if (val) { _selectedAmenities.add(amenity); } else { _selectedAmenities.remove(amenity); } }),
            selectedColor: AppColors.primaryDark.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primaryDark,
          );
        }).toList(),
      ),
    );
  }
      ),
    );
  }

  Widget _buildGallerySection() {
    int totalImages = _networkImages.length + _selectedLocalImages.length;
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
              Text('$totalImages/10 photos', style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _networkImages.length; i++) _buildImageCard(imageProvider: NetworkImage(_networkImages[i]), badgeText: i == 0 ? 'Cover' : 'Photo', onRemove: () => _removeNetworkImage(i)),
                for (int i = 0; i < _selectedLocalImages.length; i++) _buildImageCard(imageProvider: FileImage(File(_selectedLocalImages[i].path)), badgeText: 'New', onRemove: () => _removeLocalImage(i)),
                if (totalImages < 10)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: const Icon(Icons.add, color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard({required ImageProvider imageProvider, required String badgeText, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 12), width: 80, height: 80,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(11), child: Image(image: imageProvider, width: 80, height: 80, fit: BoxFit.cover)),
          Positioned(top: 4, right: 4, child: GestureDetector(onTap: onRemove, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.close, color: AppColors.error, size: 14)))),
          Positioned(bottom: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)), child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _buildSectionContainer(
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 5, maxLength: 500,
        decoration: InputDecoration(hintText: 'Describe your homestay...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildBookingAvailabilitySection() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select days when you accept bookings:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: days.map((day) {
              final isAvailable = _availableDays[day] ?? true;
              return FilterChip(
                label: Text(day.substring(0, 1).toUpperCase() + day.substring(1)),
                selected: isAvailable,
                onSelected: (val) => setState(() => _availableDays[day] = val),
                selectedColor: AppColors.primaryDark.withValues(alpha: 0.2), checkmarkColor: AppColors.primaryDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableDatesSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select specific dates to block (blackout dates):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ..._unavailableDates.map((date) => Chip(label: Text(DateFormat('MMM dd, yyyy').format(date)), onDeleted: () => setState(() => _unavailableDates.remove(date)))),
              ActionChip(label: const Text('+ Add Date'), onPressed: _selectUnavailableDate, backgroundColor: AppColors.background),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimesSection() {
    return _buildSectionContainer(
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildFieldLabel('Check-in Time'), const SizedBox(height: 8),
            DropdownButtonFormField<String>(initialValue: _checkInTime, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: _timeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (val) => setState(() => _checkInTime = val!)),
          ])),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildFieldLabel('Check-out Time'), const SizedBox(height: 8),
            DropdownButtonFormField<String>(initialValue: _checkOutTime, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: _timeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (val) => setState(() => _checkOutTime = val!)),
          ])),
        ],
      ),
    );
  }

  Widget _buildHouseRulesSection() {
    return _buildSectionContainer(
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _availableRules.map((rule) {
          final isSelected = _selectedRules.contains(rule);
          return FilterChip(
            label: Text(rule), selected: isSelected,
            onSelected: (val) => setState(() { if (val) { _selectedRules.add(rule); } else { _selectedRules.remove(rule); } }),
            selectedColor: AppColors.primaryDark.withValues(alpha: 0.2), checkmarkColor: AppColors.primaryDark,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddOnsSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Offer optional extras (e.g. Meals, Activities)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          if (_addOns.isNotEmpty)
            ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: _addOns.length,
              itemBuilder: (context, index) {
                final addOn = _addOns[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(addOn['title']), subtitle: Text('Rs. ${addOn['price']} / person'),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () => setState(() => _addOns.removeAt(index))),
                );
              },
            ),
          OutlinedButton.icon(onPressed: _showAddOnDialog, icon: const Icon(Icons.add), label: const Text('Add Optional Add-on')),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(text: TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark), children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))]));
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, String? Function(String?)? validator, Widget? prefixIcon, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller, validator: validator, keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hintText, prefixIcon: prefixIcon, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white),
    );
  }
}
