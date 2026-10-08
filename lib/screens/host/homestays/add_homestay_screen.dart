import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../services/cloudinary_service.dart';
import '../../../../models/homestay.dart';
import '../../../../repositories/homestay_repository.dart';

class AddHomestayScreen extends StatefulWidget {
  const AddHomestayScreen({super.key});

  @override
  State<AddHomestayScreen> createState() => _AddHomestayScreenState();
}

class _AddHomestayScreenState extends State<AddHomestayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homestayRepo = HomestayRepository();
  
  // Controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController(text: '1');
  final _guestsController = TextEditingController(text: '2');
  final _descriptionController = TextEditingController();

  // Basic Info
  String _propertyType = 'Entire Homestay';
  final List<String> _propertyTypes = ['Entire Homestay', 'Private Room', 'Shared Room'];

  // Amenities
  final List<String> _availableAmenities = [
    'Wi-Fi', 'Free Parking', 'Breakfast', 'Private Bathroom', 
    'Hot Water', 'Air Conditioning', 'Fan', 'Kitchen', 'Garden', 'TV'
  ];
  final List<String> _selectedAmenities = [];

  // House Rules
  final List<String> _availableRules = [
    'No Smoking', 'No Parties', 'Pets Allowed', 'Children Allowed'
  ];
  final List<String> _selectedRules = [];

  // Availability Days
  final Map<String, bool> _availableDays = {
    'monday': true, 'tuesday': true, 'wednesday': true,
    'thursday': true, 'friday': true, 'saturday': true, 'sunday': true,
  };

  // Unavailable Dates
  final List<DateTime> _unavailableDates = [];

  // Times
  String _checkInTime = '2:00 PM';
  String _checkOutTime = '11:00 AM';
  final List<String> _timeOptions = [
    '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM', '2:00 PM', 
    '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM'
  ];

  // Add-ons
  final List<Map<String, dynamic>> _addOns = [];

  // Images
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final CloudinaryService _cloudinaryService = CloudinaryService();

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
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) {
        setState(() {
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

  Future<void> _selectUnavailableDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        // Avoid duplicates
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
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title (e.g. Buffet Lunch)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (Rs.)'),
            ),
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

      // 2. Create Homestay Model
      final homestay = Homestay(
        id: '', // Will be assigned by Firestore
        hostId: user.uid,
        title: _titleController.text.trim(),
        propertyType: _propertyType,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        pricePerNight: double.tryParse(_priceController.text.trim()) ?? 0.0,
        rooms: int.tryParse(_roomsController.text.trim()) ?? 1,
        maxGuests: int.tryParse(_guestsController.text.trim()) ?? 1,
        images: imageUrls,
        amenities: _selectedAmenities,
        houseRules: _selectedRules,
        availableDays: _availableDays,
        unavailableDates: _unavailableDates,
        checkInTime: _checkInTime,
        checkOutTime: _checkOutTime,
        optionalAddOns: _addOns,
        status: 'Active',
      );

      // 3. Save to Firestore
      await _homestayRepo.createHomestay(homestay);

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
      backgroundColor: const Color(0xFFFBF9F6),
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
        title: Text(
          'Add New Homestay',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.primaryDark,
            fontSize: 18,
          ),
        ),
        actions: const [],
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
                    _buildSectionHeader('1. Basic Information'),
                    _buildBasicInfoSection(),
                    
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
                    _buildAvailabilitySection(),

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
                          Text('Save and Publish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Property Title'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hintText: 'e.g. Galewela Riverside Cottage',
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildFieldLabel('Property Type'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _propertyType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _propertyTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (val) => setState(() => _propertyType = val!),
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildFieldLabel('Location / Village Name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _locationController,
            hintText: 'e.g. Nilagama, Galewela',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primaryDark),
            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          ),
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
          _buildTextField(
            controller: _priceController,
            hintText: '3500',
            keyboardType: TextInputType.number,
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Rs.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final val = double.tryParse(value);
              if (val == null || val <= 0) return 'Invalid price';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Req';
                        final val = int.tryParse(value);
                        if (val == null || val < 1) return '>=1';
                        return null;
                      },
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
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Req';
                        final val = int.tryParse(value);
                        if (val == null || val < 1) return '>=1';
                        return null;
                      },
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

  Widget _buildAmenitiesSection() {
    return _buildSectionContainer(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableAmenities.map((amenity) {
          final isSelected = _selectedAmenities.contains(amenity);
          return FilterChip(
            label: Text(amenity),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedAmenities.add(amenity);
                } else {
                  _selectedAmenities.remove(amenity);
                }
              });
            },
            selectedColor: AppColors.primaryDark.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primaryDark,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGallerySection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
              Text('${_selectedImages.length}/10 photos', style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.bold)),
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
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tap to add photos', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (int i = 0; i < _selectedImages.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_selectedImages[i].path), width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                      if (i == 0)
                        Positioned(
                          bottom: 4, left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                if (_selectedImages.length < 10)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: const Icon(Icons.add, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _buildSectionContainer(
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 5,
        maxLength: 500,
        decoration: InputDecoration(
          hintText: 'Describe your homestay...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select days when you accept bookings:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              final isAvailable = _availableDays[day] ?? true;
              return FilterChip(
                label: Text(day.substring(0, 1).toUpperCase() + day.substring(1)),
                selected: isAvailable,
                onSelected: (val) => setState(() => _availableDays[day] = val),
                selectedColor: AppColors.primaryDark.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primaryDark,
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
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._unavailableDates.map((date) => Chip(
                label: Text(DateFormat('MMM dd, yyyy').format(date)),
                onDeleted: () => setState(() => _unavailableDates.remove(date)),
              )),
              ActionChip(
                label: const Text('+ Add Date'),
                onPressed: _selectUnavailableDate,
                backgroundColor: AppColors.background,
              ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Check-in Time'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _checkInTime,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _timeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _checkInTime = val!),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Check-out Time'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _checkOutTime,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _timeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _checkOutTime = val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseRulesSection() {
    return _buildSectionContainer(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableRules.map((rule) {
          final isSelected = _selectedRules.contains(rule);
          return FilterChip(
            label: Text(rule),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedRules.add(rule);
                } else {
                  _selectedRules.remove(rule);
                }
              });
            },
            selectedColor: AppColors.primaryDark.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primaryDark,
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addOns.length,
              itemBuilder: (context, index) {
                final addOn = _addOns[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(addOn['title']),
                  subtitle: Text('Rs. ${addOn['price']} / person'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => setState(() => _addOns.removeAt(index)),
                  ),
                );
              },
            ),
          OutlinedButton.icon(
            onPressed: _showAddOnDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Optional Add-on'),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
