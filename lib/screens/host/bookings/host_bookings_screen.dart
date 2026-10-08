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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
          bookings = bookings.where((b) => b.bookingStatus == _statusFilter).toList();
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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
    final dateFormat = DateFormat('MMM dd, yyyy');
    final checkIn = dateFormat.format(booking.checkInDate);
    final checkOut = dateFormat.format(booking.checkOutDate);

    Color statusColor = AppColors.border;
    IconData statusIcon = Icons.info_outline;

    switch (booking.bookingStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.payment;
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HostBookingDetailsScreen(booking: booking),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.homestayTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          booking.bookingStatus.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(booking.travelerName, style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('$checkIn - $checkOut', style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('${booking.guestCount} Guests', style: const TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                  Text(
                    'Rs. ${booking.totalAmount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
