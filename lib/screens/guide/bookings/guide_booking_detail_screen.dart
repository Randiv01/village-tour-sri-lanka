import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/guide_booking.dart';
import '../../../repositories/guide_booking_repository.dart';
import '../chat/guide_chat_screen.dart';

class GuideBookingDetailScreen extends StatefulWidget {
  final GuideBooking booking;
  const GuideBookingDetailScreen({super.key, required this.booking});

  @override
  State<GuideBookingDetailScreen> createState() =>
      _GuideBookingDetailScreenState();
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

  Future<void> _updateStatus(
    String newStatus, {
    String? rejectionReason,
  }) async {
    setState(() => _isLoading = true);
    try {
      if (newStatus == 'rejected') {
        await _repo.updateBookingStatus(
          _booking.id,
          newStatus,
          rejectionReason: rejectionReason,
          rejectedAt: DateTime.now(),
        );
      } else if (newStatus == 'accepted') {
        await _repo.updateBookingStatus(
          _booking.id,
          newStatus,
          acceptedAt: DateTime.now(),
        );
      } else {
        await _repo.updateBookingStatus(_booking.id, newStatus);
      }

      final updated = await _repo.getBooking(_booking.id);
      if (updated != null && mounted) {
        setState(() => _booking = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking $newStatus successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog() {
    String? selectedReason;
    final otherReasonController = TextEditingController();
    final reasons = [
      'Tour unavailable',
      'Schedule conflict',
      'Capacity issue',
      'Personal reason',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reject Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Why are you rejecting this booking?'),
                  const SizedBox(height: 8),
                  ...reasons.map(
                    (reason) => InkWell(
                      onTap: () => setState(() => selectedReason = reason),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              selectedReason == reason
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selectedReason == reason
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(reason),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (selectedReason == 'Other')
                    TextField(
                      controller: otherReasonController,
                      decoration: const InputDecoration(
                        labelText: 'Please specify',
                        border: OutlineInputBorder(),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final finalReason = selectedReason == 'Other'
                        ? otherReasonController.text
                        : selectedReason;
                    if (finalReason == null || finalReason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select or enter a reason'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _updateStatus('rejected', rejectionReason: finalReason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Booking'),
        content: const Text(
          'Accept this booking request? The traveler will be notified to make the payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus('accepted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
          'Booking Details',
          style: AppTextStyles.screenHeading.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
              if (_booking.guestEmail.isNotEmpty)
                _infoItem('Email', _booking.guestEmail),
              if (_booking.guestPhone != null &&
                  _booking.guestPhone!.isNotEmpty)
                _infoItem('Phone', _booking.guestPhone!),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _sectionLabel('TOUR PACKAGE'),
            const SizedBox(height: AppSpacing.sm),
            _infoCard([_infoItem('Package', _booking.packageTitle)]),
            const SizedBox(height: AppSpacing.lg),

            _sectionLabel('BOOKING'),
            const SizedBox(height: AppSpacing.sm),
            _infoCard([
              _infoItem('Booking ID', _booking.id),
              _infoItem(
                'Date',
                '${DateFormat('MMM dd, yyyy').format(_booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(_booking.endDate)}',
              ),
              _infoItem('Guests', _booking.numberOfGuests.toString()),
              _infoItem(
                'Total Amount',
                '${_booking.currency} ${NumberFormat('#,##0').format(_booking.totalPrice)}',
              ),
              _infoItem('Payment Status', _booking.paymentStatus.toUpperCase()),
              _infoItem(
                'Booking Status',
                _booking.status.toUpperCase(),
                valueColor: _getStatusColor(_booking.status),
              ),
            ]),
            if (_booking.notes != null && _booking.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _sectionLabel('TRIP INFORMATION'),
              const SizedBox(height: AppSpacing.sm),
              _infoCard([_infoItem('Notes', _booking.notes!)]),
            ],
            if (_booking.status == 'rejected' &&
                _booking.rejectionReason != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _sectionLabel('REJECTION REASON'),
              const SizedBox(height: AppSpacing.sm),
              _infoCard([
                _infoItem(
                  'Reason',
                  _booking.rejectionReason!,
                  valueColor: AppColors.error,
                ),
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
          Expanded(
            child: OutlinedButton(
              onPressed: _showRejectDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Reject Booking'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton(
              onPressed: _showAcceptDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Accept Booking'),
            ),
          ),
        ],
      );
    } else if (_booking.status == 'confirmed' ||
        _booking.status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _messageTraveler(),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Message Traveler'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _messageTraveler() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuideChatScreen(
          touristId: _booking.guestId,
          touristName: _booking.guestName,
          touristImage: _booking.guestProfileUrl ?? '',
          touristLanguages: 'English',
          packageId: _booking.packageId,
          packageTitle: _booking.packageTitle,
          packagePrice:
              '${_booking.currency} ${NumberFormat('#,##0').format(_booking.totalPrice)}',
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: AppTextStyles.labelLarge.copyWith(
      color: AppColors.primaryDark,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: valueColor != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textPrimary;
    }
  }
}
