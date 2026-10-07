import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/user_model.dart';
import '../../../models/tour_package.dart';
import '../../../models/guide_booking.dart';
import '../../../services/auth_service.dart';
import '../../../repositories/tour_package_repository.dart';
import '../../../repositories/guide_booking_repository.dart';
import '../packages/create_edit_package_screen.dart';
import '../packages/package_management_screen.dart';
import '../bookings/guide_booking_detail_screen.dart';

class GuideHomeScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  const GuideHomeScreen({super.key, this.onNavigate});
  @override
  State<GuideHomeScreen> createState() => _GuideHomeScreenState();
}

class _GuideHomeScreenState extends State<GuideHomeScreen> {
  final AuthService _authService = AuthService();
  final TourPackageRepository _packageRepo = TourPackageRepository();
  final GuideBookingRepository _bookingRepo = GuideBookingRepository();

  UserModel? _guideProfile;
  bool _profileLoading = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadGuideProfile();
  }

  Future<void> _loadGuideProfile() async {
    setState(() { _profileLoading = true; _profileError = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final profile = await _authService.getUserProfile(uid);
      if (mounted) setState(() { _guideProfile = profile; _profileLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _profileError = e.toString(); _profileLoading = false; });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _getFirstName(String fullName) {
    if (fullName.trim().isEmpty) return 'Guide';
    final name = fullName.trim().split(' ').first;
    if (name.isEmpty) return 'Guide';
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Background Image Header
            Positioned(
              top: 0, left: 0, right: 0,
              height: 300,
              child: Container(
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
                        AppColors.background.withValues(alpha: 0.0),
                        AppColors.background.withValues(alpha: 0.5),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            
            // Foreground Content
            _profileLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _profileError != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadGuideProfile,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildOverview(uid),
                              const SizedBox(height: AppSpacing.xl),
                              _buildCreatePackageCard(context),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildPendingBookings(context, uid),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildUpcomingBookings(context, uid),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildPackagesSection(context, uid),
                              const SizedBox(height: AppSpacing.xxxl),
                            ],
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
      const SizedBox(height: AppSpacing.md),
      Text('Could not load your profile.', style: AppTextStyles.bodyLarge),
      const SizedBox(height: AppSpacing.md),
      ElevatedButton(onPressed: _loadGuideProfile, child: const Text('Retry')),
    ]));
  }

  Widget _buildHeader() {
    final guide = _guideProfile;
    final name = guide != null ? _getFirstName(guide.fullName) : 'Guide';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getGreeting(), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                Row(
                  children: [
                    Text(name, style: AppTextStyles.displayMedium.copyWith(color: AppColors.primaryDark, height: 1.1)),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('\u{1F33F}', style: TextStyle(fontSize: 22)),
                  ],
                ),
                Row(
                  children: [
                    Text('Tour Guide', style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    if (guide?.country != null && guide!.country!.isNotEmpty) ...[
                      Text(' \u2022 ', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      Text(guide.country!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _GuideIconButton(icon: Icons.notifications_outlined, onTap: () {}, hasIndicator: true),
          const SizedBox(width: AppSpacing.sm),
          _buildProfileAvatar(guide),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel? guide) {
    return GestureDetector(
      onTap: () => widget.onNavigate?.call(3),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2)),
        child: ClipOval(
          child: guide?.profileImageUrl != null && guide!.profileImageUrl!.isNotEmpty
              ? Image.network(guide.profileImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _defaultAvatarIcon())
              : _defaultAvatarIcon(),
        ),
      ),
    );
  }

  Widget _defaultAvatarIcon() => Container(color: AppColors.primary.withValues(alpha: 0.1), child: const Icon(Icons.person, color: AppColors.primary, size: 24));

  Widget _buildOverview(String uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(child: _OverviewStat(title: 'Active\nPackages', stream: _packageRepo.getGuideActivePackagesStream(uid).map((l) => l.length), icon: Icons.explore_outlined)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _OverviewStat(title: 'Pending\nBookings', stream: _bookingRepo.getGuideBookingsStream(uid).map((l) => l.where((b) => b.status == 'pending').length), icon: Icons.pending_actions)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _OverviewStat(title: 'Upcoming\nBookings', stream: _bookingRepo.getUpcomingBookingsStream(uid).map((l) => l.length), icon: Icons.calendar_month_outlined)),
        ],
      ),
    );
  }

  Widget _buildCreatePackageCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEditPackageScreen())),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: AppRadius.cardRadius,
            boxShadow: [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Tour Package', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Share your village experiences with travelers', style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingBookings(BuildContext context, String uid) {
    return StreamBuilder<List<GuideBooking>>(
      stream: _bookingRepo.getGuideBookingsStream(uid).map((l) => l.where((b) => b.status == 'pending').toList()),
      builder: (context, snapshot) {
        final pending = snapshot.data ?? [];
        if (pending.isEmpty && snapshot.connectionState != ConnectionState.waiting) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Pending Booking Requests', style: AppTextStyles.sectionHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            ),
            const SizedBox(height: AppSpacing.md),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else
              ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: pending.length,
                separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (c, i) => _PendingBookingCard(booking: pending[i], onManage: () => _openBooking(context, pending[i])),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingBookings(BuildContext context, String uid) {
    return StreamBuilder<List<GuideBooking>>(
      stream: _bookingRepo.getUpcomingBookingsStream(uid),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Upcoming Bookings', style: AppTextStyles.sectionHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    Text('Confirmed future bookings.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ])),
                  GestureDetector(
                    onTap: () => widget.onNavigate?.call(1),
                    child: Text('View All >', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (bookings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('No upcoming bookings.', style: AppTextStyles.bodyMedium),
              )
            else
              ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: bookings.length > 3 ? 3 : bookings.length,
                separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (c, i) => _UpcomingBookingCard(booking: bookings[i], onTap: () => _openBooking(context, bookings[i])),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPackagesSection(BuildContext context, String uid) {
    return StreamBuilder<List<TourPackage>>(
      stream: _packageRepo.getGuidePackagesStream(uid),
      builder: (context, snapshot) {
        final packages = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('My Tour Packages', style: AppTextStyles.sectionHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    Text('Manage your tour packages, availability and details.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (packages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('No tour packages yet.', style: AppTextStyles.bodyMedium),
              )
            else
              ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: packages.length > 3 ? 3 : packages.length,
                separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (c, i) => _PackageCard(package: packages[i], onManage: () => _managePackage(context, packages[i])),
              ),
          ],
        );
      },
    );
  }

  void _openBooking(BuildContext context, GuideBooking booking) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GuideBookingDetailScreen(booking: booking)));
  }

  void _managePackage(BuildContext context, TourPackage package) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PackageManagementScreen(package: package)));
  }
}

class _GuideIconButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool hasIndicator;
  const _GuideIconButton({required this.icon, required this.onTap, this.hasIndicator = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
        if (hasIndicator) Positioned(top: -2, right: -2, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))),
      ]),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String title; final Stream<int> stream; final IconData icon;
  const _OverviewStat({required this.title, required this.stream, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text('$count', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark, height: 1.1));
            },
          ),
          const SizedBox(height: 2),
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.2)),
        ],
      ),
    );
  }
}

class _PendingBookingCard extends StatelessWidget {
  final GuideBooking booking; final VoidCallback onManage;
  const _PendingBookingCard({required this.booking, required this.onManage});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5))),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(booking.packageTitle, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('Pending', style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text('${booking.guestName} \u2022 ${booking.numberOfGuests} Guests', style: AppTextStyles.bodyMedium),
        Text('Date: ${DateFormat('MMM dd, yyyy').format(booking.startDate)}', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${booking.currency} ${NumberFormat('#,##0').format(booking.totalPrice)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('View Details'),
          ),
        ]),
      ]),
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  final GuideBooking booking; final VoidCallback onTap;
  const _UpcomingBookingCard({required this.booking, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(DateFormat('dd').format(booking.startDate), style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, height: 1.1)),
              Text(DateFormat('MMM').format(booking.startDate), style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ]),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.packageTitle, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${booking.guestName} \u2022 ${booking.numberOfGuests} Guests', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final TourPackage package; final VoidCallback onManage;
  const _PackageCard({required this.package, required this.onManage});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border)),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.cards)),
          child: SizedBox(
            width: 100, height: 100,
            child: package.coverImageUrl != null && package.coverImageUrl!.isNotEmpty
                ? Image.network(package.coverImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)))
                : Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(package.title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Icon(package.isActive ? Icons.check_circle : Icons.pause_circle_filled, color: package.isActive ? Colors.green : Colors.orange, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${package.durationDays} Days / ${package.nights} Nights', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                Text('Max ${package.maxGuests} Guests \u2022 Rs. ${NumberFormat('#,##0').format(package.pricePerGuest)}/guest', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onManage,
                    child: Text('Manage Package', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
