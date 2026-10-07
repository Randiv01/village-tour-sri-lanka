import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

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
  State<CreateEditPackageScreen> createState() => _CreateEditPackageScreenState();
}

class _CreateEditPackageScreenState extends State<CreateEditPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TourPackageRepository();
  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;
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

  String _status = 'active';
  bool _saving = false;

  bool get isEditing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _daysCtrl = TextEditingController(text: p?.durationDays.toString() ?? '1');
    _nightsCtrl = TextEditingController(text: p?.nights.toString() ?? '0');
    _maxGuestsCtrl = TextEditingController(text: p?.maxGuests.toString() ?? '2');
    _priceCtrl = TextEditingController(text: p?.pricePerGuest.toStringAsFixed(0) ?? '');
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
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _categoryCtrl, _daysCtrl, _nightsCtrl, _maxGuestsCtrl, _priceCtrl, _vehicleCtrl, _locationCtrl, _meetingCtrl, _pickupNotesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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

  void _addSimpleItem(String title, List<String> targetList) {
    showDialog(context: context, builder: (ctx) {
      final ctrl = TextEditingController();
      return AlertDialog(
        title: Text('Add $title'),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: 'Enter $title item')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              setState(() => targetList.add(ctrl.text.trim()));
            }
            Navigator.pop(ctx);
          }, child: const Text('Add'))
        ]
      );
    });
  }

  void _addComplexItem(String title, List<Map<String, dynamic>> targetList) {
    showDialog(context: context, builder: (ctx) {
      final titleCtrl = TextEditingController();
      final descCtrl = TextEditingController();
      return AlertDialog(
        title: Text('Add $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
          ]
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (titleCtrl.text.trim().isNotEmpty) {
              setState(() => targetList.add({'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim()}));
            }
            Navigator.pop(ctx);
          }, child: const Text('Add'))
        ]
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImageUrl == null && _coverImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover image is required.'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Upload Cover Image
      String? finalCoverUrl = _coverImageUrl;
      if (_coverImageFile != null) {
        final res = await _cloudinary.uploadImage(_coverImageFile!);
        finalCoverUrl = res?.secureUrl;
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
        category: _categoryCtrl.text.trim(),
        coverImageUrl: finalCoverUrl,
        galleryImages: finalGallery,
        durationDays: int.tryParse(_daysCtrl.text.trim()) ?? 1,
        nights: int.tryParse(_nightsCtrl.text.trim()) ?? 0,
        maxGuests: int.tryParse(_maxGuestsCtrl.text.trim()) ?? 1,
        pricePerGuest: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        vehicleType: _vehicleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        meetingPoint: _meetingCtrl.text.trim(),
        pickupNotes: _pickupNotesCtrl.text.trim(),
        includedItems: _includedList,
        excludedItems: _excludedList,
        placesToVisit: _placesList,
        activities: _activitiesList,
        itinerary: _itineraryList,
        availabilityDates: widget.package?.availabilityDates ?? [],
        status: _status,
      );

      if (isEditing) {
        await _repo.updatePackage(updatedPkg);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package updated successfully.')));
      } else {
        await _repo.createPackage(updatedPkg);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package created successfully!')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        title: Text(isEditing ? 'Edit Package' : 'Create Tour Package', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            
            // --- SECTION 1: Basic Information ---
            _sectionLabel('1. Basic Information'),
            const SizedBox(height: AppSpacing.md),
            
            // Cover Image
            Text('Cover Image *', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border, style: BorderStyle.solid)),
                child: _coverImageFile != null
                    ? ClipRRect(borderRadius: AppRadius.cardRadius, child: Image.file(File(_coverImageFile!.path), fit: BoxFit.cover))
                    : (_coverImageUrl != null && _coverImageUrl!.isNotEmpty)
                        ? ClipRRect(borderRadius: AppRadius.cardRadius, child: Image.network(_coverImageUrl!, fit: BoxFit.cover))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text('Add Cover Image', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                          ]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Additional Images
            Text('Additional Images', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ..._galleryImageUrls.map((url) => _buildImageBox(networkUrl: url, onRemove: () => setState(() => _galleryImageUrls.remove(url)))),
              ..._galleryImageFiles.map((f) => _buildImageBox(file: f, onRemove: () => setState(() => _galleryImageFiles.remove(f)))),
              GestureDetector(
                onTap: _pickGalleryImages,
                child: Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: const Icon(Icons.add, color: AppColors.primary)),
              )
            ]),
            const SizedBox(height: AppSpacing.xl),

            _field(_titleCtrl, 'Package Title *', 'e.g. Nilagama Village Explorer', required: true),
            const SizedBox(height: AppSpacing.md),
            _field(_descCtrl, 'Description *', 'Describe the experience...', maxLines: 4, required: true),
            const SizedBox(height: AppSpacing.md),
            _field(_categoryCtrl, 'Category', 'e.g. Culture & Nature'),
            const SizedBox(height: AppSpacing.xxl),

            // --- SECTION 2: Tour Details ---
            _sectionLabel('2. Tour Details'),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: _field(_daysCtrl, 'Duration (Days) *', '3', keyboardType: TextInputType.number, required: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _field(_nightsCtrl, 'Nights *', '2', keyboardType: TextInputType.number, required: true)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: _field(_maxGuestsCtrl, 'Max Guests *', '6', keyboardType: TextInputType.number, required: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _field(_priceCtrl, 'Price per Guest (Rs.) *', '8500', keyboardType: TextInputType.number, required: true)),
            ]),
            const SizedBox(height: AppSpacing.md),
            _field(_vehicleCtrl, 'Vehicle Type', 'e.g. Tuk Tuk, Car, Van'),
            const SizedBox(height: AppSpacing.md),
            _field(_locationCtrl, 'Main Location *', 'e.g. Dambulla', required: true),
            const SizedBox(height: AppSpacing.xxl),

            // --- SECTION 3: Places & Activities ---
            _sectionLabel('3. Places & Activities'),
            const SizedBox(height: AppSpacing.md),
            _buildComplexList('Places to Visit', _placesList),
            const SizedBox(height: AppSpacing.lg),
            _buildComplexList('Activities / Experiences', _activitiesList),
            const SizedBox(height: AppSpacing.xxl),

            // --- SECTION 4: Itinerary ---
            _sectionLabel('4. Itinerary'),
            const SizedBox(height: AppSpacing.md),
            _buildComplexList('Itinerary Days', _itineraryList),
            const SizedBox(height: AppSpacing.xxl),

            // --- SECTION 5: Inclusions & Exclusions ---
            _sectionLabel('5. Inclusions & Exclusions'),
            const SizedBox(height: AppSpacing.md),
            _buildSimpleList('Included Items', _includedList),
            const SizedBox(height: AppSpacing.lg),
            _buildSimpleList('Excluded Items', _excludedList),
            const SizedBox(height: AppSpacing.xxl),

            // --- SECTION 6: Meeting & Status ---
            _sectionLabel('6. Meeting & Status'),
            const SizedBox(height: AppSpacing.md),
            _field(_meetingCtrl, 'Meeting / Pickup Location', 'e.g. Hotel lobby, Bus stand'),
            const SizedBox(height: AppSpacing.md),
            _field(_pickupNotesCtrl, 'Pickup Notes', 'e.g. Please be ready 15 mins before', maxLines: 2),
            const SizedBox(height: AppSpacing.lg),
            Text('Package Status', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.inputButtonRadius, border: Border.all(color: AppColors.border)),
              child: Column(children: [
                _statusOption('active', 'Active', 'Visible and bookable'),
                const Divider(height: 1, color: AppColors.border),
                _statusOption('inactive', 'Inactive', 'Not currently available'),
                const Divider(height: 1, color: AppColors.border),
                _statusOption('draft', 'Draft', 'Saved but not visible'),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
                child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEditing ? 'Save Changes' : 'Create Tour Package'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    );
  }

  Widget _buildImageBox({String? networkUrl, XFile? file, required VoidCallback onRemove}) {
    return Stack(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: networkUrl != null ? NetworkImage(networkUrl) as ImageProvider : FileImage(File(file!.path)), fit: BoxFit.cover)),
      ),
      Positioned(
        top: 2, right: 2,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
        ),
      )
    ]);
  }

  Widget _buildSimpleList(String title, List<String> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppTextStyles.labelLarge),
        TextButton.icon(onPressed: () => _addSimpleItem(title, items), icon: const Icon(Icons.add, size: 16), label: const Text('Add'))
      ]),
      if (items.isEmpty) Text('No items added.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      for (final item in items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(item),
          trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.error), onPressed: () => setState(() => items.remove(item))),
        ),
    ]);
  }

  Widget _buildComplexList(String title, List<Map<String, dynamic>> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppTextStyles.labelLarge),
        TextButton.icon(onPressed: () => _addComplexItem(title, items), icon: const Icon(Icons.add, size: 16), label: const Text('Add'))
      ]),
      if (items.isEmpty) Text('No items added.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      for (final item in items)
        Card(
          elevation: 0, color: AppColors.surface, shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            title: Text(item['title'] ?? ''),
            subtitle: item['description'] != null ? Text(item['description']) : null,
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () => setState(() => items.remove(item))),
          ),
        ),
    ]);
  }

  Widget _sectionLabel(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
  );

  Widget _field(TextEditingController ctrl, String label, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool required = false}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboardType, style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _statusOption(String value, String title, String subtitle) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () => setState(() => _status = value),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.labelLarge),
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ])),
        ]),
      ),
    );
  }
}
