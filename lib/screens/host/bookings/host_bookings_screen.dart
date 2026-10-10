import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../models/homestay_booking.dart';
import '../../../../repositories/homestay_booking_repository.dart';
import 'host_booking_details_screen.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends State<HostBookingsScreen> {
  final _bookingRepo = HomestayBookingRepository();
  final String _hostId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _statusFilter = 'pending'; // 'pending', 'accepted', 'confirmed', 'all'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Manage Bookings',
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.primaryDark,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildBookingsList()),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Accepted (Unpaid)', 'value': 'accepted'},
      {'label': 'Confirmed', 'value': 'confirmed'},
      {'label': 'All', 'value': 'all'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _statusFilter == tab['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(tab['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _statusFilter = tab['value']!);
              },
              selectedColor: AppColors.primaryDark,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_hostId.isEmpty) {
      return const Center(child: Text('User not logged in'));
    }

    return StreamBuilder<List<HomestayBooking>>(
      stream: _bookingRepo.getHostBookings(_hostId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var bookings = snapshot.data ?? [];

        // Apply filter
        if (_statusFilter != 'all') {
          bookings = bookings
              .where((b) => b.bookingStatus == _statusFilter)
              .toList();
        }

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_busy, size: 64, color: AppColors.border),
                const SizedBox(height: 16),
                Text(
                  'No $_statusFilter bookings',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
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
    );
  }

  Widget _buildBookingCard(HomestayBooking booking) {
    final checkIn = DateFormat('MMM dd, yyyy').format(booking.checkInDate);
    final checkOut = DateFormat('MMM dd, yyyy').format(booking.checkOutDate);

    Color statusColor = AppColors.border;
    Color bgColor = Colors.transparent;
    
    switch (booking.bookingStatus) {
      case 'pending':
        statusColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'accepted':
        statusColor = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.1);
        break;
      case 'confirmed':
        statusColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'rejected':
      case 'cancelled':
        statusColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.1);
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HostBookingDetailsScreen(booking: booking),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.homestayTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.bookingStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${booking.travelerName} (${booking.guestCount} Guests)',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$checkIn - $checkOut',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'LKR ${NumberFormat('#,##0').format(booking.totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HostBookingDetailsScreen(booking: booking),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
