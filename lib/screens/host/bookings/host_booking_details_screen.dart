import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../models/homestay_booking.dart';
import '../../../../repositories/homestay_booking_repository.dart';
import '../../../../services/email_service.dart';

class HostBookingDetailsScreen extends StatefulWidget {
  final HomestayBooking booking;

  const HostBookingDetailsScreen({super.key, required this.booking});

  @override
  State<HostBookingDetailsScreen> createState() =>
      _HostBookingDetailsScreenState();
}

class _HostBookingDetailsScreenState extends State<HostBookingDetailsScreen> {
  final _bookingRepo = HomestayBookingRepository();
  bool _isProcessing = false;

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    try {
      await _bookingRepo.updateBookingStatus(widget.booking.id, 'accepted');
      
      // ✉️ Send status update email
      await EmailService.notifyTravelerStatusUpdate(
        toEmail: widget.booking.travelerEmail,
        customerName: widget.booking.travelerName,
        bookingId: widget.booking.id,
        status: 'Accepted',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking accepted. Awaiting payment.'),
            backgroundColor: Colors.green,
          ),
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject() async {
    String? selectedReason;
    final reasonController = TextEditingController();
    final reasons = [
      'Homestay unavailable',
      'Schedule conflict',
      'Maintenance issues',
      'Personal reason',
      'Other',
    ];

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
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
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Please specify',
                      border: OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final finalReason = selectedReason == 'Other'
                      ? reasonController.text.trim()
                      : selectedReason;
                  if (finalReason == null || finalReason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select or enter a reason')),
                    );
                    return;
                  }
                  reasonController.text = finalReason; // Store for outside
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (shouldReject == true) {
      setState(() => _isProcessing = true);
      try {
        await _bookingRepo.updateBookingStatus(
          widget.booking.id,
          'rejected',
          rejectionReason: reasonController.text.trim(),
        );

        // ✉️ Send status update email for rejection
        await EmailService.notifyTravelerStatusUpdate(
          toEmail: widget.booking.travelerEmail,
          customerName: widget.booking.travelerName,
          bookingId: widget.booking.id,
          status: 'rejected',
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rejected.'),
              backgroundColor: Colors.orange,
            ),
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
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Booking Request',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.primaryDark,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(b),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionContainer(
              title: 'Homestay',
              child: Text(
                b.homestayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionContainer(
              title: 'Guest Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Name', b.travelerName),
                  _buildDetailRow('Email', b.travelerEmail),
                  _buildDetailRow('Guests', '${b.guestCount} Person(s)'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionContainer(
              title: 'Stay Dates',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Check-in', dateFormat.format(b.checkInDate)),
                  _buildDetailRow(
                    'Check-out',
                    dateFormat.format(b.checkOutDate),
                  ),
                  _buildDetailRow('Duration', '${b.numberOfNights} Night(s)'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (b.selectedAddOns.isNotEmpty) ...[
              _buildSectionContainer(
                title: 'Requested Add-ons',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: b.selectedAddOns.map((addon) {
                    return _buildDetailRow(
                      addon['title'],
                      'Rs. ${addon['price']} x ${addon['quantity']}',
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            _buildSectionContainer(
              title: 'Payment Summary',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Accommodation',
                    'Rs. ${b.accommodationAmount}',
                  ),
                  if (b.addOnAmount > 0)
                    _buildDetailRow('Add-ons', 'Rs. ${b.addOnAmount}'),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Rs. ${b.totalAmount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Payment Status',
                    b.paymentStatus.toUpperCase(),
                  ),
                ],
              ),
            ),

            if (b.bookingStatus == 'rejected' && b.rejectionReason != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildSectionContainer(
                title: 'Rejection Reason',
                child: Text(
                  b.rejectionReason!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: b.bookingStatus == 'pending' ? _buildBottomActions() : null,
    );
  }

  Widget _buildStatusCard(HomestayBooking b) {
    Color color = AppColors.border;
    String message = '';

    if (b.bookingStatus == 'pending') {
      color = Colors.orange;
      message = 'This is a new request. Please accept or reject.';
    } else if (b.bookingStatus == 'accepted') {
      color = Colors.blue;
      message = 'Request accepted. Waiting for guest payment.';
    } else if (b.bookingStatus == 'confirmed') {
      color = Colors.green;
      message = 'Booking confirmed and paid.';
    } else if (b.bookingStatus == 'rejected') {
      color = AppColors.error;
      message = 'You rejected this booking.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _handleReject,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
