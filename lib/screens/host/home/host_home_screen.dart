import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import 'widgets/analytics_stat_card.dart';
import 'widgets/host_homestay_card.dart';
import 'widgets/upcoming_booking_tile.dart';
import '../promotions/my_promotions_screen.dart';
import '../homestays/add_homestay_screen.dart';
import '../homestays/update_homestay_screen.dart';
import '../../common/homestays/homestay_details_screen.dart';

class HostHomeScreen extends StatelessWidget {
  const HostHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
            _buildUpcomingBookingsSection(),
            const SizedBox(height: AppSpacing.xxl),
            _buildPromotionsSection(context),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else if (hour < 21) {
      return 'Good evening,';
    } else {
      return 'Good night,';
    }
  }

  Widget _buildTopBanner(BuildContext context) {
    return Stack(
      children: [
        // Background landscape image with fade
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/sign-in/auth_rural_landscape.png'),
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
        
        // SafeArea content
        SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseAuth.instance.currentUser != null 
                ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
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

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Notification and Profile Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Stack(
                            children: [
                              const Icon(Icons.notifications_none, color: AppColors.primaryDark),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty 
                              ? NetworkImage(avatarUrl) 
                              : null,
                          backgroundColor: AppColors.softSecondarySurface,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? const Icon(Icons.person, color: AppColors.textSecondary)
                              : null,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Welcome Text
                    Text(
                      _getGreeting(),
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
                          'Homestay Host',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.circle, size: 4, color: AppColors.secondary),
                        ),
                        Text(
                          'Nilagama',
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
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            AnalyticsStatCard(
              topIcon: Icons.payments_outlined,
              title: "This Month's Revenue",
              value: "Rs. 48,500",
              bottomWidget: Row(
                children: [
                  const Icon(Icons.trending_up, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    "+18.4%",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "vs last month",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnalyticsStatCard(
              topIcon: Icons.calendar_today_outlined,
              title: "Upcoming Guests",
              value: "6",
              width: 130,
              bottomWidget: const Text(
                "Next 7 days",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnalyticsStatCard(
              topIcon: Icons.king_bed_outlined,
              title: "Occupancy Rate",
              value: "70%",
              width: 140,
              bottomWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: AppColors.softSecondarySurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddHomestayScreen()));
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
                          'Add New Homestay',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'List your village stay for travelers',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
          ? FirebaseFirestore.instance.collection('homestays').where('hostId', isEqualTo: user.uid).snapshots()
          : null,
      builder: (context, snapshot) {
        int listedCount = 0;
        List<Widget> homestayCards = [];

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          listedCount = docs.length;
          
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final images = List<String>.from(data['images'] ?? []);
            final imageUrl = images.isNotEmpty ? images.first : 'assets/images/onboarding/onboarding_01.png';
            
            homestayCards.add(
              HostHomestayCard(
                title: data['title'] ?? 'Unnamed Homestay',
                location: data['location'] ?? 'Unknown Location',
                roomsInfo: '${data['roomsCount'] ?? 1} Rooms  |  Up to ${data['maxGuests'] ?? 2} Guests',
                priceInfo: 'Rs. ${data['pricePerNight']?.toString() ?? '0'}/night',
                occupancyInfo: '0% Booked', // placeholder logic
                status: data['status'] ?? 'Active',
                imageUrl: imageUrl, 
              )
            );
          }
        }

        if (homestayCards.isEmpty) {
          homestayCards.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('No homestays listed yet.', style: TextStyle(color: AppColors.textSecondary)),
          ));
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
                        'My Homestays',
                        style: AppTextStyles.sectionHeading.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$listedCount Listed',
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
                    onTap: () {},
                    child: Row(
                      children: [
                        Text(
                          'Manage All ',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.secondary),
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
                child: Row(
                  children: homestayCards,
                ),
              )
            else
              ...homestayCards,
          ],
        );
      }
    );
  }

  Widget _buildUpcomingBookingsSection() {
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
                'Upcoming Bookings',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View All ',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.secondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const UpcomingBookingTile(
            guestName: 'Emma Wilson',
            dateRange: '14 Oct 2024 - 16 Oct 2024',
            guestsInfo: '2 Guests',
            propertyName: 'Nilagama\nVillage House',
            status: 'Confirmed',
            avatarUrl: 'https://i.pravatar.cc/150?img=1', // placeholder
          ),
          const UpcomingBookingTile(
            guestName: 'Luca Bianchi',
            dateRange: '22 Oct 2024 - 25 Oct 2024',
            guestsInfo: '3 Guests',
            propertyName: 'Ruwan Villa\nHomestay',
            status: 'Pending',
            avatarUrl: 'https://i.pravatar.cc/150?img=11', // placeholder
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsSection(BuildContext context) {
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
                'My Promotions',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyPromotionsScreen()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View All ',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.secondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPromotionsScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF1E3), // Warm yellow-orange tint
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.5), // match image
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_offer, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a Promotion',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Offer special rates or seasonal discounts',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
