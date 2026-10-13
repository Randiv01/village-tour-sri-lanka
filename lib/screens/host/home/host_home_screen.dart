import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import 'widgets/host_homestay_card.dart';
import 'widgets/upcoming_booking_tile.dart';
import '../homestays/add_homestay_screen.dart';
import '../homestays/update_homestay_screen.dart';
import '../../common/homestays/homestay_details_screen.dart';
import '../../../../models/homestay.dart';
import '../../../../models/homestay_booking.dart';
import '../bookings/host_bookings_screen.dart';
import '../notifications/host_notifications_screen.dart';
import '../../../../repositories/notification_repository.dart';
import '../../../../services/host_language_service.dart';
import 'widgets/analytics_stat_card.dart';
import 'widgets/host_language_toggle_button.dart';

class HostHomeScreen extends StatelessWidget {
  final VoidCallback? onGoToBookings;
  final VoidCallback? onGoToProfile;

  const HostHomeScreen({super.key, this.onGoToBookings, this.onGoToProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBanner(context),
            _buildAnalyticsRow(),
            const SizedBox(height: AppSpacing.xl),
            _buildAddNewHomestayButton(context),
            const SizedBox(height: AppSpacing.xxl),
            _buildMyHomestaysSection(),
            const SizedBox(height: AppSpacing.xxl),
            _buildUpcomingBookingsSection(context),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Stack(
      children: [
        // Background landscape image with fade
        Positioned.fill(
          child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/images/sign-in/auth_rural_landscape.png',
              ),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.1),
                  AppColors.background.withValues(alpha: 0.8),
                  AppColors.background,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),
        ),

        // SafeArea content
        SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots()
                : null,
            builder: (context, snapshot) {
              String? avatarUrl;
              String firstName = 'Host';

              if (snapshot.hasData && snapshot.data!.data() != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                avatarUrl = data['profileImageUrl'] as String?;
                final fullName = data['fullName'] as String? ?? 'Host';
                firstName = fullName.split(' ').first;
              }

              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Menu, Language Toggle, Notification, Profile
                    Row(
                      children: [
                        Builder(
                          builder: (ctx) => InkWell(
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const HostLanguageToggleButton(),
                        const SizedBox(width: AppSpacing.sm),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HostNotificationsScreen(),
                              ),
                            );
                          },
                          child: StreamBuilder<int>(
                            stream: currentUserId != null
                                ? NotificationRepository()
                                    .getTotalUnreadCountForHost(currentUserId)
                                : const Stream.empty(),
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.data ?? 0;
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(
                                      Icons.notifications_none,
                                      color: AppColors.primaryDark,
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E6B52),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            unreadCount > 99
                                                ? '99+'
                                                : unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        GestureDetector(
                          onTap: onGoToProfile,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            backgroundColor: AppColors.softSecondarySurface,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Welcome Text
                    Text(
                      HostTranslation.ayubowan,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$firstName ',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.primaryDark,
                              height: 1.2,
                              fontSize: 32,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text('🌿', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          HostTranslation.homestayHost,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.circle,
                            size: 4,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          'Nilagama Cluster • ${HostTranslation.superhost}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
                .collection('homestay_bookings')
                .where('hostId', isEqualTo: user.uid)
                .snapshots()
          : null,
      builder: (context, bookingSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance
                    .collection('homestays')
                    .where('hostId', isEqualTo: user.uid)
                    .snapshots()
              : null,
          builder: (context, homestaySnapshot) {
            final now = DateTime.now();
            final currentYear = now.year;
            final currentMonth = now.month;

            final prevMonthDate = DateTime(currentYear, currentMonth - 1);
            final prevYear = prevMonthDate.year;
            final prevMonth = prevMonthDate.month;

            final allBookings = (bookingSnapshot.hasData)
                ? bookingSnapshot.data!.docs.map((doc) {
                    return HomestayBooking.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList()
                : <HomestayBooking>[];

            final validBookings = allBookings
                .where((b) =>
                    b.bookingStatus != 'cancelled' &&
                    b.bookingStatus != 'rejected')
                .toList();

            // 1. This Month's Revenue
            double thisMonthRevenue = 0.0;
            double lastMonthRevenue = 0.0;

            for (final b in validBookings) {
              if (b.checkInDate.year == currentYear &&
                  b.checkInDate.month == currentMonth) {
                thisMonthRevenue += b.totalAmount;
              } else if (b.checkInDate.year == prevYear &&
                  b.checkInDate.month == prevMonth) {
                lastMonthRevenue += b.totalAmount;
              }
            }

            String growthText;
            Color growthColor;
            IconData growthIcon;

            if (lastMonthRevenue > 0) {
              final growth =
                  ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) *
                  100;
              if (growth >= 0) {
                growthText = "+${growth.toStringAsFixed(1)}%";
                growthColor = Colors.green[700]!;
                growthIcon = Icons.trending_up;
              } else {
                growthText = "${growth.toStringAsFixed(1)}%";
                growthColor = Colors.red[700]!;
                growthIcon = Icons.trending_down;
              }
            } else {
              if (thisMonthRevenue > 0) {
                growthText = "+100%";
                growthColor = Colors.green[700]!;
                growthIcon = Icons.trending_up;
              } else {
                growthText = "0%";
                growthColor = AppColors.textSecondary;
                growthIcon = Icons.trending_flat;
              }
            }

            final formattedRevenue =
                NumberFormat('#,##0').format(thisMonthRevenue.toInt());

            // 2. Upcoming Guests (next 7 days)
            final sevenDaysLater = now.add(const Duration(days: 7));
            int upcomingGuestsCount = 0;

            for (final b in validBookings) {
              final arrivesSoon =
                  b.checkInDate.isAfter(now.subtract(const Duration(days: 1))) &&
                  b.checkInDate.isBefore(sevenDaysLater);
              final isStaying =
                  b.checkInDate.isBefore(now) && b.checkOutDate.isAfter(now);
              if (arrivesSoon || isStaying) {
                upcomingGuestsCount += b.guestCount;
              }
            }

            // 3. Occupancy Rate
            final totalHomestays =
                homestaySnapshot.hasData ? homestaySnapshot.data!.docs.length : 0;
            final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
            final totalAvailableNights = totalHomestays * daysInMonth;

            final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
            final lastDayOfMonth =
                DateTime(currentYear, currentMonth, daysInMonth, 23, 59, 59);

            int bookedNightsThisMonth = 0;
            for (final b in validBookings) {
              if (b.checkOutDate.isAfter(firstDayOfMonth) &&
                  b.checkInDate.isBefore(lastDayOfMonth)) {
                final start = b.checkInDate.isBefore(firstDayOfMonth)
                    ? firstDayOfMonth
                    : b.checkInDate;
                final end = b.checkOutDate.isAfter(lastDayOfMonth)
                    ? lastDayOfMonth
                    : b.checkOutDate;
                final diff = end.difference(start).inDays;
                bookedNightsThisMonth += (diff <= 0 ? 1 : diff);
              }
            }

            double occupancyFraction = 0.0;
            if (totalAvailableNights > 0) {
              occupancyFraction =
                  (bookedNightsThisMonth / totalAvailableNights).clamp(0.0, 1.0);
            }
            final occupancyPercent = (occupancyFraction * 100).toInt();

            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    AnalyticsStatCard(
                      topIcon: Icons.payments_outlined,
                      title: HostTranslation.thisMonthRevenue,
                      value: "Rs. $formattedRevenue",
                      width: 170,
                      bottomWidget: Row(
                        children: [
                          Icon(growthIcon, size: 14, color: growthColor),
                          const SizedBox(width: 4),
                          Text(
                            growthText,
                            style: TextStyle(
                              color: growthColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            HostTranslation.vsLastMonth,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AnalyticsStatCard(
                      topIcon: Icons.calendar_today_outlined,
                      title: HostTranslation.upcomingGuests,
                      value: "$upcomingGuestsCount",
                      width: 130,
                      bottomWidget: Text(
                        HostTranslation.next7Days,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AnalyticsStatCard(
                      topIcon: Icons.king_bed_outlined,
                      title: HostTranslation.occupancyRate,
                      value: "$occupancyPercent%",
                      width: 140,
                      bottomWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: occupancyFraction,
                              backgroundColor: AppColors.softSecondarySurface,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg), // right padding
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddNewHomestayButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddHomestayScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HostTranslation.addNewHomestay,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          HostTranslation.listYourVillageStay,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyHomestaysSection() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
                .collection('homestays')
                .where('hostId', isEqualTo: user.uid)
                .snapshots()
          : null,
      builder: (context, snapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance
                    .collection('homestay_bookings')
                    .where('hostId', isEqualTo: user.uid)
                    .snapshots()
              : null,
          builder: (context, bookingSnapshot) {
            int listedCount = 0;
            List<Widget> homestayCards = [];

            final allBookings = (bookingSnapshot.hasData)
                ? bookingSnapshot.data!.docs.map((doc) {
                    return HomestayBooking.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList()
                : <HomestayBooking>[];

            final validBookings = allBookings
                .where((b) =>
                    b.bookingStatus != 'cancelled' &&
                    b.bookingStatus != 'rejected')
                .toList();

            final now = DateTime.now();
            final currentYear = now.year;
            final currentMonth = now.month;
            final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
            final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
            final lastDayOfMonth =
                DateTime(currentYear, currentMonth, daysInMonth, 23, 59, 59);

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;
              listedCount = docs.length;

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final images = List<String>.from(data['images'] ?? []);
                final imageUrl = images.isNotEmpty
                    ? images.first
                    : 'assets/images/onboarding/onboarding_01.png';

                int bookedNightsForHomestay = 0;
                for (final b in validBookings) {
                  if (b.homestayId == doc.id &&
                      b.checkOutDate.isAfter(firstDayOfMonth) &&
                      b.checkInDate.isBefore(lastDayOfMonth)) {
                    final start = b.checkInDate.isBefore(firstDayOfMonth)
                        ? firstDayOfMonth
                        : b.checkInDate;
                    final end = b.checkOutDate.isAfter(lastDayOfMonth)
                        ? lastDayOfMonth
                        : b.checkOutDate;
                    final diff = end.difference(start).inDays;
                    bookedNightsForHomestay += (diff <= 0 ? 1 : diff);
                  }
                }

                final homestayOccupancy = daysInMonth > 0
                    ? ((bookedNightsForHomestay / daysInMonth) * 100)
                        .toInt()
                        .clamp(0, 100)
                    : 0;

                homestayCards.add(
                  HostHomestayCard(
                    title: data['title'] ?? 'Unnamed Homestay',
                    location: data['location'] ?? 'Unknown Location',
                    roomsInfo:
                        '${data['roomsCount'] ?? 1} ${HostTranslation.rooms}  |  ${HostTranslation.upTo} ${data['maxGuests'] ?? 2} ${HostTranslation.guests}',
                    priceInfo:
                        'Rs. ${data['pricePerNight']?.toString() ?? '0'}${HostTranslation.perNight}',
                    occupancyInfo:
                        '$homestayOccupancy% ${HostTranslation.booked}',
                    status: data['status'] ?? 'Active',
                    imageUrl: imageUrl,
                    onTapManage: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateHomestayScreen(
                            homestay: Homestay.fromMap(data, doc.id),
                          ),
                        ),
                      );
                    },
                    onTapCard: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HomestayDetailsScreen(homestayId: doc.id),
                        ),
                      );
                    },
                  ),
                );
              }
            }

        if (homestayCards.isEmpty) {
          homestayCards.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                HostTranslation.noHomestaysYet,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        } else {
          homestayCards.add(const SizedBox(width: 8)); // Right padding
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        HostTranslation.myHomestays,
                        style: AppTextStyles.sectionHeading.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$listedCount ${HostTranslation.listed}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onGoToBookings ?? () {},
                    child: Row(
                      children: [
                        Text(
                          HostTranslation.manageAll,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (listedCount > 0)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                clipBehavior: Clip.none,
                child: Row(children: homestayCards),
              )
            else
              ...homestayCards,
            ],
          );
        },
      );
    },
  );
}

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildUpcomingBookingsSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                HostTranslation.upcomingBookings,
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HostBookingsScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      HostTranslation.viewAll,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StreamBuilder<QuerySnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance
                      .collection('homestay_bookings')
                      .where('hostId', isEqualTo: user.uid)
                      .snapshots()
                : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  HostTranslation.noUpcomingBookings,
                  style: const TextStyle(color: AppColors.textSecondary),
                );
              }

              final now = DateTime.now();
              final bookings = snapshot.data!.docs
                  .map((doc) {
                    return HomestayBooking.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  })
                  .where(
                    (b) =>
                        b.checkOutDate.isAfter(now) &&
                        b.bookingStatus != 'cancelled' &&
                        b.bookingStatus != 'rejected',
                  )
                  .toList();

              bookings.sort((a, b) => a.checkInDate.compareTo(b.checkInDate));

              if (bookings.isEmpty) {
                return Text(
                  HostTranslation.noUpcomingBookings,
                  style: const TextStyle(color: AppColors.textSecondary),
                );
              }

              return Column(
                children: bookings.take(3).map((booking) {
                  final inDate =
                      '${booking.checkInDate.day} ${_getMonth(booking.checkInDate.month)} ${booking.checkInDate.year}';
                  final outDate =
                      '${booking.checkOutDate.day} ${_getMonth(booking.checkOutDate.month)} ${booking.checkOutDate.year}';

                  return UpcomingBookingTile(
                    guestName: booking.travelerName,
                    dateRange: '$inDate - $outDate',
                    guestsInfo: '${booking.guestCount} ${HostTranslation.guests}',
                    propertyName: booking.homestayTitle,
                    status:
                        booking.bookingStatus[0].toUpperCase() +
                        booking.bookingStatus.substring(1),
                    avatarUrl:
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(booking.travelerName)}&background=random',
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}












