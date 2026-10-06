import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/guide_booking.dart';
import '../../../repositories/guide_booking_repository.dart';

class GuideBookingDetailScreen extends StatefulWidget {
  final GuideBooking booking;
  const GuideBookingDetailScreen({super.key, required this.booking});

  @override
  State<GuideBookingDetailScreen> createState() => _GuideBookingDetailScreenState();
}

class _GuideBookingDetailScreenState extends State<GuideBookingDetailScreen> {
  final _repo = GuideBookingRepository();
  late GuideBooking _booking;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    try {
      await _repo.updateBookingStatus(_booking.id, status);
      if (mounted) {
        setState(() { _booking = GuideBooking(id: _booking.id, guideId: _booking.guideId, packageId: _booking.packageId, packageTitle: _booking.packageTitle, guestId: _booking.guestId, guestName: _booking.guestName, guestEmail: _booking.guestEmail, guestPhone: _booking.guestPhone, startDate: _booking.startDate, endDate: _booking.endDate, numberOfGuests: _booking.numberOfGuests, totalPrice: _booking.totalPrice, currency: _booking.currency, status: status, notes: _booking.notes, tourType: _booking.tourType, createdAt: _booking.createdAt, updatedAt: DateTime.now()); _updating = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $status.'), backgroundColor: AppColors.primary));
      }
    } catch (e) {
      if (mounted) { setState(() => _updating = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)); }
    }
  }

  Color _statusColor(String s) { switch (s.toLowerCase()) { case 'confirmed': return Colors.green; case 'pending': return AppColors.secondary; case 'cancelled': return AppColors.error; default: return AppColors.textSecondary; } }
  Color _statusBg(String s) { switch (s.toLowerCase()) { case 'confirmed': return Colors.green.withValues(alpha: 0.1); case 'pending': return AppColors.secondary.withValues(alpha: 0.1); case 'cancelled': return AppColors.error.withValues(alpha: 0.1); default: return AppColors.softSecondarySurface; } }
  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        title: Text('Booking Details', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status + Package
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(_booking.packageTitle, style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: _statusBg(_booking.status), borderRadius: BorderRadius.circular(12)),
                  child: Text(_cap(_booking.status), style: AppTextStyles.caption.copyWith(color: _statusColor(_booking.status), fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              _infoRow(Icons.calendar_today_outlined, 'Dates', '${df.format(_booking.startDate)} – ${df.format(_booking.endDate)}'),
              const SizedBox(height: AppSpacing.sm),
              _infoRow(Icons.group_outlined, 'Guests', '${_booking.numberOfGuests} Guests • ${_booking.tourType}'),
              const SizedBox(height: AppSpacing.sm),
              _infoRow(Icons.attach_money, 'Total', 'Rs. ${_booking.totalPrice.toStringAsFixed(0)}'),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Guest info
          Text('Guest Information', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
            child: Column(children: [
              _infoRow(Icons.person_outline, 'Name', _booking.guestName),
              const SizedBox(height: AppSpacing.sm),
              _infoRow(Icons.email_outlined, 'Email', _booking.guestEmail),
              if (_booking.guestPhone != null && _booking.guestPhone!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _infoRow(Icons.phone_outlined, 'Phone', _booking.guestPhone!),
              ],
              if (_booking.notes != null && _booking.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _infoRow(Icons.note_outlined, 'Notes', _booking.notes!),
              ],
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Actions
          if (_booking.status == 'pending') ...[
            Text('Booking Actions', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: ElevatedButton(
                onPressed: _updating ? null : () => _updateStatus('confirmed'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                child: const Text('Confirm'),
              )),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: OutlinedButton(
                onPressed: _updating ? null : () => _updateStatus('cancelled'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                child: const Text('Decline'),
              )),
            ]),
          ] else if (_booking.status == 'confirmed') ...[
            Text('Booking Actions', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _updating ? null : () => _updateStatus('completed'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
              child: const Text('Mark as Completed'),
            )),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: _updating ? null : () => _updateStatus('cancelled'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
              child: const Text('Cancel Booking'),
            )),
          ],
          const SizedBox(height: AppSpacing.xxxl),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
      ])),
    ]);
  }
}
