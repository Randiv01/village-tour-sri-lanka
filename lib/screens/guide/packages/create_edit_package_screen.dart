import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/tour_package.dart';
import '../../../repositories/tour_package_repository.dart';

class CreateEditPackageScreen extends StatefulWidget {
  final TourPackage? package;
  const CreateEditPackageScreen({super.key, this.package});

  @override
  State<CreateEditPackageScreen> createState() => _CreateEditPackageScreenState();
}

class _CreateEditPackageScreenState extends State<CreateEditPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TourPackageRepository();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _vehicleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _maxGuestsCtrl;
  late TextEditingController _daysCtrl;
  late TextEditingController _nightsCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _includedCtrl;
  late TextEditingController _excludedCtrl;

  String _status = 'active';
  bool _saving = false;

  bool get isEditing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _locationCtrl = TextEditingController(text: p?.location ?? '');
    _vehicleCtrl = TextEditingController(text: p?.vehicleType ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toStringAsFixed(0) ?? '');
    _maxGuestsCtrl = TextEditingController(text: p?.maxGuests.toString() ?? '2');
    _daysCtrl = TextEditingController(text: p?.durationDays.toString() ?? '1');
    _nightsCtrl = TextEditingController(text: p?.durationNights.toString() ?? '0');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _includedCtrl = TextEditingController(text: p?.includedItems.join(', ') ?? '');
    _excludedCtrl = TextEditingController(text: p?.excludedItems.join(', ') ?? '');
    _status = p?.status ?? 'active';
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _locationCtrl, _vehicleCtrl, _priceCtrl, _maxGuestsCtrl, _daysCtrl, _nightsCtrl, _categoryCtrl, _includedCtrl, _excludedCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final includedList = _includedCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final excludedList = _excludedCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      if (isEditing) {
        final updated = widget.package!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          vehicleType: _vehicleCtrl.text.trim(),
          price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
          maxGuests: int.tryParse(_maxGuestsCtrl.text.trim()) ?? 1,
          durationDays: int.tryParse(_daysCtrl.text.trim()) ?? 1,
          durationNights: int.tryParse(_nightsCtrl.text.trim()) ?? 0,
          category: _categoryCtrl.text.trim(),
          includedItems: includedList,
          excludedItems: excludedList,
          status: _status,
        );
        await _repo.updatePackage(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package updated successfully.'), backgroundColor: AppColors.primary));
          Navigator.pop(context, true);
        }
      } else {
        final newPkg = TourPackage(
          id: '',
          guideId: uid,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          vehicleType: _vehicleCtrl.text.trim(),
          price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
          maxGuests: int.tryParse(_maxGuestsCtrl.text.trim()) ?? 1,
          durationDays: int.tryParse(_daysCtrl.text.trim()) ?? 1,
          durationNights: int.tryParse(_nightsCtrl.text.trim()) ?? 0,
          category: _categoryCtrl.text.trim(),
          includedItems: includedList,
          excludedItems: excludedList,
          status: _status,
        );
        await _repo.createPackage(newPkg);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tour package created successfully!'), backgroundColor: AppColors.primary));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: '), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(isEditing ? 'Edit Package' : 'Create Tour Package', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('Basic Information'),
            const SizedBox(height: AppSpacing.sm),
            _field(_titleCtrl, 'Package Title', 'e.g. Nilagama Village Explorer', required: true),
            const SizedBox(height: AppSpacing.md),
            _field(_descCtrl, 'Description', 'Describe what travelers will experience...', maxLines: 4, required: true),
            const SizedBox(height: AppSpacing.md),
            _field(_categoryCtrl, 'Category', 'e.g. Culture & Nature, Heritage & Adventure'),
            const SizedBox(height: AppSpacing.xxl),

            _sectionLabel('Tour Details'),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _field(_daysCtrl, 'Duration (Days)', '3', keyboardType: TextInputType.number, required: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _field(_nightsCtrl, 'Nights', '2', keyboardType: TextInputType.number, required: true)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: _field(_maxGuestsCtrl, 'Max Guests', '6', keyboardType: TextInputType.number, required: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _field(_priceCtrl, 'Price (Rs.)', '28500', keyboardType: TextInputType.number, required: true)),
            ]),
            const SizedBox(height: AppSpacing.md),
            _field(_vehicleCtrl, 'Vehicle Type', 'e.g. KDH Van (Private)'),
            const SizedBox(height: AppSpacing.md),
            _field(_locationCtrl, 'Location', 'e.g. Nilagama, Galewela', required: true),
            const SizedBox(height: AppSpacing.xxl),

            _sectionLabel('Inclusions & Exclusions'),
            const SizedBox(height: AppSpacing.sm),
            _field(_includedCtrl, 'Included Items', 'Meals, Transport, Guide (comma-separated)', maxLines: 2),
            const SizedBox(height: AppSpacing.md),
            _field(_excludedCtrl, 'Excluded Items', 'Personal expenses, Tips (comma-separated)', maxLines: 2),
            const SizedBox(height: AppSpacing.xxl),

            _sectionLabel('Status'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.inputButtonRadius, border: Border.all(color: AppColors.border)),
              child: Column(children: [
                _statusOption('active', 'Active', 'Visible to travelers'),
                const Divider(height: 1, color: AppColors.border),
                _statusOption('inactive', 'Inactive', 'Hidden from travelers'),
                const Divider(height: 1, color: AppColors.border),
                _statusOption('draft', 'Draft', 'Saved but not published'),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
                child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEditing ? 'Update Package' : 'Create Package'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold));

  Widget _field(TextEditingController ctrl, String label, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _statusOption(String value, String title, String subtitle) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () => setState(() => _status = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
