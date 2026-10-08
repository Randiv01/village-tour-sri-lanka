import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../models/guide_booking.dart';
import '../../../../services/payment_service.dart';

class TravelerBookingsScreen extends StatefulWidget {
  const TravelerBookingsScreen({super.key});

  @override
  State<TravelerBookingsScreen> createState() => _TravelerBookingsScreenState();
}

class _TravelerBookingsScreenState extends State<TravelerBookingsScreen> {
  final PaymentService _paymentService = PaymentService();
  
  Stream<List<GuideBooking>> _getBookingsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    
    return FirebaseFirestore.instance
        .collection('guide_bookings')
        .where('guestId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => GuideBooking.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(2000)) ?? 0);
          return bookings;
        });
  }

  void _handlePayNow(GuideBooking booking) {
    _paymentService.processMockPayment(
      context: context,
      bookingId: booking.id,
      bookingType: 'tour_package',
      userId: booking.guestId,
      amount: booking.totalPrice,
      currency: booking.currency,
      description: 'Tour Package: ${booking.packageTitle}',
      onComplete: (success, transactionId) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful! Booking confirmed.')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Bookings', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<GuideBooking>>(
        stream: _getBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('You have no bookings yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(GuideBooking booking) {
    Color statusColor = Colors.grey;
    String statusText = booking.status.toUpperCase();
    bool showPayNow = false;

    if (booking.status == 'pending') {
      statusColor = Colors.orange;
      statusText = 'WAITING FOR GUIDE APPROVAL';
    } else if (booking.status == 'accepted') {
      statusColor = Colors.blue;
      if (booking.paymentStatus == 'unpaid') {
        statusText = 'BOOKING ACCEPTED - PAYMENT REQUIRED';
        showPayNow = true;
      } else if (booking.paymentStatus == 'failed') {
        statusText = 'PAYMENT FAILED - PLEASE RETRY';
        statusColor = Colors.red;
        showPayNow = true;
      }
    } else if (booking.status == 'confirmed') {
      statusColor = Colors.green;
      statusText = 'BOOKING CONFIRMED';
    } else if (booking.status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'BOOKING REJECTED';
    } else if (booking.status == 'cancelled') {
      statusColor = Colors.red;
      statusText = 'BOOKING CANCELLED';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    booking.packageTitle,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${DateFormat('dd MMM yyyy').format(booking.startDate)} - ${DateFormat('dd MMM yyyy').format(booking.endDate)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Guests: ${booking.numberOfGuests}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Total: Rs. ${NumberFormat('#,##0').format(booking.totalPrice)}',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            
            if (booking.status == 'rejected' && booking.rejectionReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${booking.rejectionReason}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (showPayNow) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handlePayNow(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Pay Now'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
