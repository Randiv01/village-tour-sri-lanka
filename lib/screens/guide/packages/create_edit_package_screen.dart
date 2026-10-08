import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/tour_package.dart';
import '../../../repositories/tour_package_repository.dart';
import '../../../services/cloudinary_service.dart';

class CreateEditPackageScreen extends StatefulWidget {
  final TourPackage? package;
  const CreateEditPackageScreen({super.key, this.package});

  @override
  State<CreateEditPackageScreen> createState() =>
      _CreateEditPackageScreenState();
}

class _CreateEditPackageScreenState extends State<CreateEditPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TourPackageRepository();
  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  String? _selectedCategory;
  late TextEditingController _daysCtrl;
  late TextEditingController _nightsCtrl;
  late TextEditingController _maxGuestsCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _vehicleCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _meetingCtrl;
  late TextEditingController _pickupNotesCtrl;

  List<String> _includedList = [];
  List<String> _excludedList = [];
  List<Map<String, dynamic>> _placesList = [];
  List<Map<String, dynamic>> _activitiesList = [];
  List<Map<String, dynamic>> _itineraryList = [];

  String? _coverImageUrl;
  XFile? _coverImageFile;
  List<String> _galleryImageUrls = [];
  final List<XFile> _galleryImageFiles = [];

  // Availability dates - sorted list
  List<DateTime> _unavailableDates = [];
  Map<String, bool> _availableDays = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': true,
    'sunday': true,
  };

  String _status = 'active';
  bool _saving = false;

  bool get isEditing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');

    String initialCategory = p?.category ?? 'Village Experience';
    if (!TourPackage.packageCategories.contains(initialCategory)) {
      initialCategory = 'Other Experience';
    }
    _selectedCategory = initialCategory;

    _daysCtrl = TextEditingController(text: p?.durationDays.toString() ?? '1');
    _nightsCtrl = TextEditingController(text: p?.nights.toString() ?? '0');
    _maxGuestsCtrl =
        TextEditingController(text: p?.maxGuests.toString() ?? '2');
    _priceCtrl =
        TextEditingController(text: p?.pricePerGuest.toStringAsFixed(0) ?? '');
    _vehicleCtrl = TextEditingController(text: p?.vehicleType ?? '');
    _locationCtrl = TextEditingController(text: p?.location ?? '');
    _meetingCtrl = TextEditingController(text: p?.meetingPoint ?? '');
    _pickupNotesCtrl = TextEditingController(text: p?.pickupNotes ?? '');

    if (p != null) {
      _coverImageUrl = p.coverImageUrl;
      _galleryImageUrls = List.from(p.galleryImages);
      _includedList = List.from(p.includedItems);
      _excludedList = List.from(p.excludedItems);
      _placesList = List.from(p.placesToVisit);
      _activitiesList = List.from(p.activities);
      _itineraryList = List.from(p.itinerary);
      _status = p.status;
      // Load existing availability dates
      _unavailableDates = List.from(p.unavailableDates);
      _unavailableDates.sort();
      _availableDays = Map<String, bool>.from(p.availableDays);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _daysCtrl,
      _nightsCtrl,
      _maxGuestsCtrl,
      _priceCtrl,
      _vehicleCtrl,
      _locationCtrl,
      _meetingCtrl,
      _pickupNotesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _coverImageFile = image;
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _galleryImageFiles.addAll(images);
      });
    }
  }

  /// Opens Flutter's built-in date picker and adds the selected date to the list.
  /// Past dates and already-selected dates are disallowed.
  Future<void> _pickUnavailableDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime(today.year + 2, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Available Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
              surface: AppColors.surface,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    // Normalise to midnight so comparisons work
    final normalised = DateTime(picked.year, picked.month, picked.day);

    // Prevent adding duplicate dates
    final alreadyExists = _unavailableDates.any(
      (d) => d.year == normalised.year && d.month == normalised.month && d.day == normalised.day,
    );

    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This date is already selected as a blackout date.')),
        );
      }
      return;
    }

    setState(() {
      _unavailableDates.add(normalised);
      _unavailableDates.sort();
    });
  }

  void _removeUnavailableDate(DateTime date) {
    setState(() {
      _unavailableDates.removeWhere(
        (d) => d.year == date.year && d.month == date.month && d.day == date.day,
      );
    });
  }

  void _addSimpleItem(String title, List<String> targetList) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text('Add $title'),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(hintText: 'Enter $title item'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  setState(() => targetList.add(ctrl.text.trim()));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addComplexItem(String title, List<Map<String, dynamic>> targetList) {
    showDialog(
      context: context,
      builder: (ctx) {
        final titleCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        return AlertDialog(
          title: Text('Add $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() => targetList.add({
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                      }));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Cross-field validations
    if (_titleCtrl.text.trim().length < 3 ||
        _titleCtrl.text.trim().length > 100) {
      _showError('Title must be between 3 and 100 characters.');
      return;
    }
    if (_descCtrl.text.trim().length < 20 ||
        _descCtrl.text.trim().length > 2000) {
      _showError('Description must be between 20 and 2000 characters.');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Category is required.');
      return;
    }

    final duration = int.tryParse(_daysCtrl.text.trim()) ?? 0;
    final nights = int.tryParse(_nightsCtrl.text.trim()) ?? -1;
    if (duration < 1) {
      _showError('Duration must be at least 1 day.');
      return;
    }
    if (nights < 0 || nights > duration) {
      _showError('Nights must be >= 0 and cannot be greater than duration.');
      return;
    }

    final guests = int.tryParse(_maxGuestsCtrl.text.trim()) ?? 0;
    if (guests < 1 || guests > 50) {
      _showError('Max guests must be between 1 and 50.');
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    if (price <= 0) {
      _showError('Price must be greater than 0.');
      return;
    }

    if (_locationCtrl.text.trim().isEmpty) {
      _showError('Main location is required.');
      return;
    }

    if (_coverImageUrl == null && _coverImageFile == null) {
      _showError('Cover image is required.');
      return;
    }

    // Active package specific validations
    if (_status == 'active') {
      if (_placesList.isEmpty && _activitiesList.isEmpty) {
        _showError(
            'Active packages require at least one place to visit or activity.');
        return;
      }
      if (_itineraryList.isEmpty) {
        _showError('Active packages require at least one itinerary item.');
        return;
      }
      if (_meetingCtrl.text.trim().isEmpty) {
        _showError(
            'Active packages require a meeting/pickup location.');
        return;
      }
      if (_vehicleCtrl.text.trim().isEmpty) {
        _showError(
            'Active packages require a vehicle type if transport is included.');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Upload Cover Image
      String? finalCoverUrl = _coverImageUrl;
      if (_coverImageFile != null) {
        final res = await _cloudinary.uploadImage(_coverImageFile!);
        if (res == null) throw Exception('Cover image upload failed.');
        finalCoverUrl = res.secureUrl;
      }

      // Upload Gallery Images
      List<String> finalGallery = List.from(_galleryImageUrls);
      for (final f in _galleryImageFiles) {
        final res = await _cloudinary.uploadImage(f);
        if (res != null) finalGallery.add(res.secureUrl);
      }

      final updatedPkg = TourPackage(
        id: isEditing ? widget.package!.id : '',
        guideId: uid,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _selectedCategory,
        coverImageUrl: finalCoverUrl,
        galleryImages: finalGallery,
        durationDays: duration,
        nights: nights,
        maxGuests: guests,
        pricePerGuest: price,
        vehicleType: _vehicleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        meetingPoint: _meetingCtrl.text.trim(),
        pickupNotes: _pickupNotesCtrl.text.trim(),
        includedItems: _includedList,
        excludedItems: _excludedList,
        placesToVisit: _placesList,
        activities: _activitiesList,
        itinerary: _itineraryList,
        availableDays: _availableDays,
        unavailableDates: _unavailableDates,
        status: _status,
      );

      if (isEditing) {
        await _repo.updatePackage(updatedPkg);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tour package updated successfully.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        await _repo.createPackage(updatedPkg);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tour package created successfully.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Package' : 'Create Tour Package',
          style: AppTextStyles.screenHeading
              .copyWith(color: AppColors.primaryDark),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SECTION 1: Basic Information ──────────────────────────
              _sectionLabel('1. Basic Information'),
              const SizedBox(height: AppSpacing.md),

              // Cover Image
              Text('Cover Image *', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _coverImageFile != null
                      ? ClipRRect(
                          borderRadius: AppRadius.cardRadius,
                          child: Image.file(
                            File(_coverImageFile!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : (_coverImageUrl != null && _coverImageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: AppRadius.cardRadius,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    _coverImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Change',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to Add Cover Image',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Additional Images
              Text('Additional Images', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._galleryImageUrls.map(
                    (url) => _buildImageBox(
                      networkUrl: url,
                      onRemove: () =>
                          setState(() => _galleryImageUrls.remove(url)),
                    ),
                  ),
                  ..._galleryImageFiles.map(
                    (f) => _buildImageBox(
                      file: f,
                      onRemove: () =>
                          setState(() => _galleryImageFiles.remove(f)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickGalleryImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppColors.primary, size: 22),
                          SizedBox(height: 2),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              _field(_titleCtrl, 'Package Title *', 'e.g. Nilagama Village Explorer',
                  required: true),
              const SizedBox(height: AppSpacing.md),
              _field(
                _descCtrl,
                'Description *',
                'Describe the experience...',
                maxLines: 4,
                required: true,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: TourPackage.packageCategories
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── SECTION 2: Tour Details ───────────────────────────────
              _sectionLabel('2. Tour Details'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _daysCtrl,
                      'Duration (Days) *',
                      '3',
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _field(
                      _nightsCtrl,
                      'Nights *',
                      '2',
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _maxGuestsCtrl,
                      'Max Guests *',
                      '6',
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _field(
                      _priceCtrl,
                      'Price / Guest (Rs.) *',
                      '8500',
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _field(
                _vehicleCtrl,
                'Vehicle Type',
                'e.g. Tuk Tuk, Car, Van',
              ),
              const SizedBox(height: AppSpacing.md),
              _field(
                _locationCtrl,
                'Main Location *',
                'e.g. Dambulla',
                required: true,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── SECTION 3: Available Dates & Blackout ─────────────────
              _sectionLabel('3. Availability'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select the days of the week this tour is typically available.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
                ].map((day) {
                  final isSelected = _availableDays[day] == true;
                  return FilterChip(
                    label: Text(day.substring(0, 1).toUpperCase() + day.substring(1)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _availableDays[day] = selected;
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primaryDark,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              Text('Blackout Dates', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add specific dates when you are NOT available to conduct this tour.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Add Date Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickUnavailableDate,
                  icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                  label: Text(
                    'Add Blackout Date',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.inputButtonRadius),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Selected dates display
              if (_unavailableDates.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.softSecondarySurface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_available, size: 32, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('No blackout dates added.', style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: _unavailableDates.asMap().entries.map((entry) {
                      final index = entry.key;
                      final date = entry.value;
                      final isLast = index == _unavailableDates.length - 1;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
                            title: Text(DateFormat('EEEE, d MMMM yyyy').format(date), style: AppTextStyles.bodyMedium),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: AppColors.error),
                              onPressed: () => _removeUnavailableDate(date),
                            ),
                          ),
                          if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),

              // ── SECTION 4: Places & Activities ───────────────────────
              _sectionLabel('4. Places & Activities'),
              const SizedBox(height: AppSpacing.md),
              _buildComplexList('Places to Visit', _placesList),
              const SizedBox(height: AppSpacing.lg),
              _buildComplexList('Activities / Experiences', _activitiesList),
              const SizedBox(height: AppSpacing.xxl),

              // ── SECTION 5: Itinerary ──────────────────────────────────
              _sectionLabel('5. Itinerary'),
              const SizedBox(height: AppSpacing.md),
              _buildComplexList('Itinerary Days', _itineraryList),
              const SizedBox(height: AppSpacing.xxl),

              // ── SECTION 6: Inclusions & Exclusions ───────────────────
              _sectionLabel('6. Inclusions & Exclusions'),
              const SizedBox(height: AppSpacing.md),
              _buildSimpleList('Included Items', _includedList),
              const SizedBox(height: AppSpacing.lg),
              _buildSimpleList('Excluded Items', _excludedList),
              const SizedBox(height: AppSpacing.xxl),

              // ── SECTION 7: Meeting & Status ───────────────────────────
              _sectionLabel('7. Meeting & Status'),
              const SizedBox(height: AppSpacing.md),
              _field(
                _meetingCtrl,
                'Meeting / Pickup Location',
                'e.g. Hotel lobby, Bus stand',
              ),
              const SizedBox(height: AppSpacing.md),
              _field(
                _pickupNotesCtrl,
                'Pickup Notes',
                'e.g. Please be ready 15 mins before',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Package Status', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.inputButtonRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _statusOption('active', 'Active', 'Visible and bookable'),
                    const Divider(height: 1, color: AppColors.border),
                    _statusOption(
                        'inactive', 'Inactive', 'Not currently available'),
                    const Divider(height: 1, color: AppColors.border),
                    _statusOption('draft', 'Draft', 'Saved but not visible'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing
                              ? 'Save Changes'
                              : 'Create Tour Package',
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageBox({
    String? networkUrl,
    XFile? file,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: networkUrl != null
                  ? NetworkImage(networkUrl) as ImageProvider
                  : FileImage(File(file!.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleList(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.labelLarge),
            TextButton.icon(
              onPressed: () => _addSimpleItem(title, items),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        if (items.isEmpty)
          Text(
            'No items added.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(item),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.error),
              onPressed: () => setState(() => items.remove(item)),
            ),
          ),
      ],
    );
  }

  Widget _buildComplexList(
    String title,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.labelLarge),
            TextButton.icon(
              onPressed: () => _addComplexItem(title, items),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        if (items.isEmpty)
          Text(
            'No items added.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        for (final item in items)
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(item['title'] ?? ''),
              subtitle:
                  item['description'] != null && item['description'].isNotEmpty
                      ? Text(item['description'])
                      : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => setState(() => items.remove(item)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _statusOption(String value, String title, String subtitle) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () => setState(() => _status = value),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
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
