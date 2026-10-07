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
  late GuideBooking _booking;
  final GuideBookingRepository _repo = GuideBookingRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _repo.updateBookingStatus(_booking.id, newStatus);
      final updated = await _repo.getBooking(_booking.id);
      if (updated != null && mounted) {
        setState(() => _booking = updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking $newStatus successfully.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('TRAVELER'),
            const SizedBox(height: AppSpacing.sm),
            _infoCard([
              _infoItem('Name', _booking.guestName),
              if (_booking.guestEmail.isNotEmpty) _infoItem('Email', _booking.guestEmail),
              if (_booking.guestPhone != null && _booking.guestPhone!.isNotEmpty) _infoItem('Phone', _booking.guestPhone!),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _sectionLabel('TOUR PACKAGE'),
            const SizedBox(height: AppSpacing.sm),
            _infoCard([
              _infoItem('Package', _booking.packageTitle),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _sectionLabel('BOOKING'),
            const SizedBox(height: AppSpacing.sm),
            _infoCard([
              _infoItem('Booking ID', _booking.id),
              _infoItem('Date', '${DateFormat('MMM dd, yyyy').format(_booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(_booking.endDate)}'),
              _infoItem('Guests', _booking.numberOfGuests.toString()),
              _infoItem('Total Amount', '${_booking.currency} ${NumberFormat('#,##0').format(_booking.totalPrice)}'),
              _infoItem('Payment Status', _booking.paymentStatus.toUpperCase()),
              _infoItem('Booking Status', _booking.status.toUpperCase(), valueColor: _getStatusColor(_booking.status)),
            ]),
            if (_booking.notes != null && _booking.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _sectionLabel('TRIP INFORMATION'),
              const SizedBox(height: AppSpacing.sm),
              _infoCard([
                _infoItem('Notes', _booking.notes!),
              ]),
            ],
            const SizedBox(height: AppSpacing.xxxl),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildActions(),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_booking.status == 'pending') {
      return Row(
        children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _updateStatus('rejected'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Reject Booking'),
          )),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: ElevatedButton(
            onPressed: () => _updateStatus('confirmed'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Accept Booking'),
          )),
        ],
      );
    } else if (_booking.status == 'confirmed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _messageTraveler(),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Message Traveler'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _messageTraveler() {
    // Navigate to a simple chat screen placeholder
    Navigator.push(context, MaterialPageRoute(builder: (_) => _MessageTravelerScreen(booking: _booking)));
  }

  Widget _sectionLabel(String text) => Text(text, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold));

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border)),
      child: Column(children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const Divider(height: 1, color: AppColors.border),
        ],
      ]),
    );
  }

  Widget _infoItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
          Expanded(flex: 3, child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: valueColor ?? AppColors.textPrimary, fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.green;
      case 'completed': return AppColors.primary;
      case 'cancelled':
      case 'rejected': return AppColors.error;
      default: return AppColors.textPrimary;
    }
  }
}

class _MessageTravelerScreen extends StatelessWidget {
  final GuideBooking booking;
  const _MessageTravelerScreen({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark, elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.guestName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(booking.packageTitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: Text('Chat messages will appear here.', style: AppTextStyles.bodySecondary))),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surface, border: const Border(top: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Expanded(child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true, fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              )),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(backgroundColor: AppColors.primary, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () {})),
            ]),
          )
        ],
      ),
    );
  }
}
