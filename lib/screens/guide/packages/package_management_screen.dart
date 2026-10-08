import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';

import '../../../models/tour_package.dart';
import '../../../repositories/tour_package_repository.dart';
import 'create_edit_package_screen.dart';

class PackageManagementScreen extends StatefulWidget {
  final TourPackage package;
  const PackageManagementScreen({super.key, required this.package});

  @override
  State<PackageManagementScreen> createState() => _PackageManagementScreenState();
}

class _PackageManagementScreenState extends State<PackageManagementScreen> {
  late TourPackage _package;
  final TourPackageRepository _repo = TourPackageRepository();
  bool _isLoading = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _package = widget.package;
  }

  Future<void> _refresh() async {
    final updated = await _repo.getPackage(_package.id);
    if (updated != null && mounted) setState(() => _package = updated);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tour Package?'),
        content: const Text('This package will no longer be available to travelers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    await _repo.updatePackageStatus(_package.id, 'inactive'); // soft delete
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _edit() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEditPackageScreen(package: _package)));
    if (result == true) {
      _refresh();
    }
  }

  void _manageAvailability() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability management coming soon!')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    List<String> allImages = [];
    if (_package.coverImageUrl != null && _package.coverImageUrl!.isNotEmpty) {
      allImages.add(_package.coverImageUrl!);
    }
    for (var img in _package.galleryImages) {
      if (img.isNotEmpty && !allImages.contains(img)) {
        allImages.add(img);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_package.title, style: const TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryDark),
            onSelected: (val) {
              if (val == 'edit') {
                _edit();
              } else if (val == 'availability') {
                _manageAvailability();
              } else if (val == 'delete') {
                _delete();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Package')),
              const PopupMenuItem(value: 'availability', child: Text('Manage Availability')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Package', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (allImages.isNotEmpty)
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: allImages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          allImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                    if (allImages.length > 1)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${allImages.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                height: 250,
                color: AppColors.primaryDark,
                width: double.infinity,
                child: const Icon(Icons.image, size: 64, color: Colors.white54),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_package.title, style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _package.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(_package.status.toUpperCase(), style: AppTextStyles.caption.copyWith(color: _package.isActive ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  Text('Rs. ${NumberFormat('#,##0').format(_package.pricePerGuest)} / guest', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.lg),
                  
                  _infoRow(Icons.timer_outlined, 'Duration', '${_package.durationDays} Days / ${_package.nights} Nights'),
                  _infoRow(Icons.group_outlined, 'Max Guests', '${_package.maxGuests} people'),
                  _infoRow(Icons.directions_car_outlined, 'Vehicle', _package.vehicleType),
                  _infoRow(Icons.location_on_outlined, 'Location', _package.location),
                  const SizedBox(height: AppSpacing.lg),
                  
                  Text('Description', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_package.description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xxl),

                  if (_package.placesToVisit.isNotEmpty) ...[
                    _sectionLabel('Places to Visit'),
                    ..._package.placesToVisit.map((e) => _listItem(e['title'] ?? '', e['description'])),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  if (_package.activities.isNotEmpty) ...[
                    _sectionLabel('Activities'),
                    ..._package.activities.map((e) => _listItem(e['title'] ?? '', e['description'])),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  if (_package.itinerary.isNotEmpty) ...[
                    _sectionLabel('Itinerary'),
                    ..._package.itinerary.map((e) => _listItem(e['title'] ?? '', e['description'])),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  if (_package.includedItems.isNotEmpty || _package.excludedItems.isNotEmpty) ...[
                    _sectionLabel('Inclusions & Exclusions'),
                    if (_package.includedItems.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text('Included:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ..._package.includedItems.map((e) => _checkItem(e, true)),
                    ],
                    if (_package.excludedItems.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text('Excluded:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ..._package.excludedItems.map((e) => _checkItem(e, false)),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  if (_package.meetingPoint != null && _package.meetingPoint!.isNotEmpty) ...[
                    _sectionLabel('Meeting Point'),
                    Text(_package.meetingPoint!, style: AppTextStyles.bodyMedium),
                    if (_package.pickupNotes != null && _package.pickupNotes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(_package.pickupNotes!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text('$label:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(text, style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
  );

  Widget _listItem(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 8, color: AppColors.primary)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null && subtitle.isNotEmpty) Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ])),
        ],
      ),
    );
  }

  Widget _checkItem(String text, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Row(children: [
        Icon(isIncluded ? Icons.check : Icons.close, size: 16, color: isIncluded ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ]),
    );
  }
}
