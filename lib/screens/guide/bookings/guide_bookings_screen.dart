import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/guide_booking.dart';
import '../../../repositories/guide_booking_repository.dart';
import 'guide_booking_detail_screen.dart';

class GuideBookingsScreen extends StatefulWidget {
  const GuideBookingsScreen({super.key});

  @override
  State<GuideBookingsScreen> createState() => _GuideBookingsScreenState();
}

class _GuideBookingsScreenState extends State<GuideBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GuideBookingRepository _repo = GuideBookingRepository();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('My Bookings', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<GuideBooking>>(
        stream: _repo.getGuideBookingsStream(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Unable to load bookings.', style: AppTextStyles.bodyLarge),
            ]));
          }

          final allBookings = snapshot.data ?? [];
          final pending = allBookings.where((b) => b.status == 'pending').toList();
          final upcoming = allBookings.where((b) => (b.status == 'confirmed' || b.status == 'accepted') && b.startDate.isAfter(DateTime.now())).toList();
          final completed = allBookings.where((b) => b.status == 'completed' || (b.status == 'confirmed' && b.startDate.isBefore(DateTime.now()))).toList();
          final cancelled = allBookings.where((b) => b.status == 'cancelled' || b.status == 'rejected').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(pending, 'No pending bookings.'),
              _buildBookingList(upcoming, 'No upcoming bookings.'),
              _buildBookingList(completed, 'No completed bookings.'),
              _buildBookingList(cancelled, 'No cancelled bookings.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<GuideBooking> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_note, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.lg),
            Text(emptyMessage, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(booking: booking, onTap: () => _openBooking(booking));
      },
    );
  }

  void _openBooking(GuideBooking booking) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GuideBookingDetailScreen(booking: booking)));
  }
}

class _BookingCard extends StatelessWidget {
  final GuideBooking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(booking.packageTitle, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            _buildStatusBadge(booking.status),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${booking.guestName} (${booking.numberOfGuests} Guests)', style: AppTextStyles.bodyMedium),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${DateFormat('MMM dd, yyyy').format(booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(booking.endDate)}', style: AppTextStyles.bodyMedium),
          ]),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Amount', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              Text('${booking.currency} ${NumberFormat('#,##0').format(booking.totalPrice)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark)),
            ]),
            TextButton(onPressed: onTap, child: const Text('View Details')),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'accepted': color = Colors.blue; break;
      case 'confirmed': color = Colors.green; break;
      case 'completed': color = AppColors.primary; break;
      case 'cancelled':
      case 'rejected': color = AppColors.error; break;
      default: color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
