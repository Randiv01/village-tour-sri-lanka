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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final repo = GuideBookingRepository();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Bookings', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'All'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<List<GuideBooking>>(
        stream: repo.getGuideBookingsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load bookings.', style: AppTextStyles.bodyLarge));
          }
          final all = snapshot.data ?? [];
          final now = DateTime.now();
          final upcoming = all.where((b) => b.startDate.isAfter(now) && (b.status == 'confirmed' || b.status == 'pending')).toList();
          final completed = all.where((b) => b.status == 'completed' || b.endDate.isBefore(now)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingList(bookings: upcoming, emptyMessage: 'No upcoming bookings.', emptySubtitle: 'Your upcoming confirmed and pending bookings will appear here.'),
              _BookingList(bookings: all, emptyMessage: 'No bookings yet.', emptySubtitle: 'All your tour bookings will appear here.'),
              _BookingList(bookings: completed, emptyMessage: 'No completed bookings.', emptySubtitle: 'Completed tour bookings will appear here.'),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<GuideBooking> bookings;
  final String emptyMessage;
  final String emptySubtitle;

  const _BookingList({required this.bookings, required this.emptyMessage, required this.emptySubtitle});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.lg),
          Text(emptyMessage, style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: AppSpacing.sm),
          Text(emptySubtitle, textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
        ]),
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(
          booking: booking,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuideBookingDetailScreen(booking: booking))),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final GuideBooking booking; final VoidCallback onTap;
  const _BookingCard({required this.booking, required this.onTap});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'pending': return AppColors.secondary;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed': return Colors.green.withValues(alpha: 0.1);
      case 'pending': return AppColors.secondary.withValues(alpha: 0.1);
      case 'cancelled': return AppColors.error.withValues(alpha: 0.1);
      default: return AppColors.softSecondarySurface;
    }
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.person, color: AppColors.primary, size: 22)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.guestName, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('${df.format(booking.startDate)} – ${df.format(booking.endDate)}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text('${booking.numberOfGuests} Guests • ${booking.tourType}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(booking.packageTitle, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: AppSpacing.sm),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _statusBg(booking.status), borderRadius: BorderRadius.circular(12)),
              child: Text(_cap(booking.status), style: AppTextStyles.caption.copyWith(color: _statusColor(booking.status), fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ]),
        ]),
      ),
    );
  }
}
