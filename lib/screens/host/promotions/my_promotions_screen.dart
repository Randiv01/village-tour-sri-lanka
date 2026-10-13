import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../repositories/share_repository.dart';
import '../../common/homestays/homestay_details_screen.dart';

class MyPromotionsScreen extends StatefulWidget {
  const MyPromotionsScreen({super.key});

  @override
  State<MyPromotionsScreen> createState() => _MyPromotionsScreenState();
}

class _MyPromotionsScreenState extends State<MyPromotionsScreen> {
  final ShareRepository _shareRepo = ShareRepository();
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'All Time'];

  String? _selectedHomestayId;
  String _selectedHomestayTitle = 'All Village Homestays';
  String _selectedHomestayLocation = 'Sri Lanka';
  double _selectedHomestayPrice = 4500;

  String _getReferralLink(String uid) {
    final targetId = _selectedHomestayId ?? 'explore';
    return 'https://villagetour.lk/homestay/$targetId?ref=$uid';
  }

  Future<void> _shareHomestayViaPlatform({
    required String uid,
    required String platform,
    String? homestayId,
    String? homestayTitle,
    String? homestayLocation,
    double? pricePerNight,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final hId = homestayId ?? _selectedHomestayId ?? 'general_referral';
    final hTitle = homestayTitle ?? _selectedHomestayTitle;
    final hLoc = homestayLocation ?? _selectedHomestayLocation;
    final hPrice = pricePerNight ?? _selectedHomestayPrice;
    final link = 'https://villagetour.lk/homestay/$hId?ref=$uid';

    final message =
        '🏡 Check out this amazing village homestay!\n\n'
        '$hTitle – $hLoc\n'
        '⭐ Authentic rural experience in Sri Lanka\n'
        '💰 From Rs. ${hPrice.toInt()}/night\n\n'
        'Book via Village Tour SL:\n$link';

    try {
      await _shareRepo.trackShareClick(
        sharerId: uid,
        homestayId: hId,
        homestayTitle: hTitle,
        homestayLocation: hLoc,
        platform: platform,
      );
    } catch (_) {}

    if (platform == 'copy') {
      await Clipboard.setData(ClipboardData(text: link));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Referral link copied! +1 Click & +Rs. ${ShareRepository.rewardPerClickLkr.toInt()} tracked.',
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      return;
    }

    if (platform == 'whatsapp') {
      final waUrl = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
        return;
      }
    } else if (platform == 'facebook') {
      final fbUrl = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}&quote=${Uri.encodeComponent(message)}',
      );
      if (await canLaunchUrl(fbUrl)) {
        await launchUrl(fbUrl, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // ignore: deprecated_member_use
    await Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primaryDark),
          title: const Text('My Promotions'),
        ),
        body: const Center(
          child: Text('Please sign in to view your Promotion Dashboard.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'VILLAGE SANCTUARY',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _shareRepo.getClicksStream(currentUser.uid),
        builder: (context, clickSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('homestay_bookings')
                .snapshots(),
            builder: (context, bookingSnapshot) {
              final clickDocs = clickSnapshot.data?.docs ?? [];
              final bookingDocs = bookingSnapshot.data?.docs ?? [];

              final analytics = ShareRepository.computeAnalytics(
                clickDocs: clickDocs,
                bookingDocs: bookingDocs,
                uid: currentUser.uid,
                periodFilter: _selectedPeriod,
              );

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'AFFILIATE & REACH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Promotions',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 28,
                            ),
                          ),
                          _buildPeriodFilterDropdown(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildLinkClicksCard(analytics),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _buildBookingsCard(analytics)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _buildEarningsCard(analytics)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildEarningsOverTimeCard(analytics),
                      const SizedBox(height: AppSpacing.xl),
                      _buildBookingSourcesCard(analytics),
                      if (analytics.sharedHomestays.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _buildSharedHomestaysCard(analytics, currentUser.uid),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _buildReferralAndSocialShareCard(currentUser.uid),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilterDropdown() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _selectedPeriod = value;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => _periods
          .map(
            (p) => PopupMenuItem<String>(
              value: p,
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _selectedPeriod == p
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedPeriod.replaceAll(' ', '\n'),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.1,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkClicksCard(ShareAnalyticsData analytics) {
    final formattedClicks = NumberFormat('#,##0').format(analytics.totalClicks);
    final isPositive = analytics.weeklyGrowthPercent >= 0;
    final growthText =
        '${isPositive ? '+' : ''}${analytics.weeklyGrowthPercent.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.remove_red_eye,
              color: AppColors.primaryDark.withValues(alpha: 0.7),
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Link Clicks',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedClicks,
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 10,
                            color: isPositive ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            growthText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPositive
                                  ? Colors.green[700]
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 20),
              Text(
                '${analytics.thisWeekClicks} this wk',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const Text(
                'vs prev wk',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsCard(ShareAnalyticsData analytics) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bookings',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryDark,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${analytics.totalBookings}',
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.primaryDark,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Active & confirmed stays',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(ShareAnalyticsData analytics) {
    final formattedEarnings =
        NumberFormat('#,##0').format(analytics.totalEarnings.toInt());

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Earnings',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.secondary,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Rs. ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Flexible(
                child: Text(
                  formattedEarnings,
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.arrow_upward, size: 10, color: Colors.green),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  'Rs. ${ShareRepository.rewardPerClickLkr.toInt()}/click + 5% stay',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsOverTimeCard(ShareAnalyticsData analytics) {
    final entries = analytics.dailyEarnings.entries.toList();
    double maxEarning = 0;
    String peakDay = '';
    for (final e in entries) {
      if (e.value > maxEarning) {
        maxEarning = e.value;
        peakDay = e.key;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings & Clicks\nOver Time (Last 7 Days)',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${analytics.thisWeekClicks} clicks (7d)',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Daily referral click rewards & booking payouts (LKR)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 185,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final day = entry.key;
                final val = entry.value;
                final clicks = analytics.dailyClicks[day] ?? 0;
                final isPeak = maxEarning > 0 && day == peakDay;
                final double factor = maxEarning > 0
                    ? (val / maxEarning).clamp(0.12, 1.0)
                    : 0.12;

                String labelVal;
                if (val >= 1000) {
                  labelVal = '${(val / 1000).toStringAsFixed(1)}k';
                } else {
                  labelVal = val.toInt().toString();
                }

                Color barColor;
                if (isPeak) {
                  barColor = AppColors.secondary;
                } else if (val > 0) {
                  barColor = AppColors.primaryDark;
                } else {
                  barColor = const Color(0xFFF4F0E8);
                }

                return _buildBar(
                  day: day,
                  valueLabel: 'Rs.$labelVal',
                  clicksCount: clicks,
                  heightFactor: factor,
                  color: barColor,
                  isPeak: isPeak,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.secondary, 'Peak Day'),
              const SizedBox(width: 12),
              _buildLegendItem(AppColors.primaryDark, 'Active Day'),
              const SizedBox(width: 12),
              _buildLegendItem(const Color(0xFFF4F0E8), 'No Clicks'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String day,
    required String valueLabel,
    required int clicksCount,
    required double heightFactor,
    required Color color,
    required bool isPeak,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPeak)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F0E8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'Peak ($clicksCount)\n$valueLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                height: 1.1,
                color: AppColors.primaryDark,
              ),
            ),
          )
        else
          Text(
            clicksCount > 0 ? '$clicksCount clk\n$valueLabel' : '0',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.textSecondary,
              height: 1.1,
            ),
          ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
            color: isPeak ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBookingSourcesCard(ShareAnalyticsData analytics) {
    final total = analytics.totalClicks;
    final waCount = analytics.platformBreakdown['whatsapp'] ?? 0;
    final fbCount = analytics.platformBreakdown['facebook'] ?? 0;
    final igCount = analytics.platformBreakdown['instagram'] ?? 0;
    final copyCount =
        (analytics.platformBreakdown['copy'] ?? 0) +
        (analytics.platformBreakdown['other'] ?? 0);

    double pct(int count) => total > 0 ? (count / total) : 0.0;
    String pctLabel(int count) =>
        '$count clicks (${(pct(count) * 100).toStringAsFixed(0)}%)';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Social Share Sources',
                style: AppTextStyles.sectionHeading.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                ),
              ),
              Text(
                '${NumberFormat('#,##0').format(total)} total clicks',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSourceItem(
            Icons.chat_bubble_outline,
            'WhatsApp Share Link',
            pctLabel(waCount),
            pct(waCount),
            const Color(0xFF25D366),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSourceItem(
            Icons.facebook_outlined,
            'Facebook Social Share',
            pctLabel(fbCount),
            pct(fbCount),
            const Color(0xFF1877F2),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSourceItem(
            Icons.camera_alt_outlined,
            'Instagram Travel Link',
            pctLabel(igCount),
            pct(igCount),
            const Color(0xFFE1306C),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSourceItem(
            Icons.link_rounded,
            'Direct Link Copy & Other',
            pctLabel(copyCount),
            pct(copyCount),
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceItem(
    IconData icon,
    String title,
    String percentage,
    double value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              percentage,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFF4F0E8),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedHomestaysCard(
    ShareAnalyticsData analytics,
    String uid,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shared Homestays Performance',
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.primaryDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Click counts per homestay you shared',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.md),
          ...analytics.sharedHomestays.take(5).map((item) {
            final hId = item['homestayId'] as String;
            final hTitle = item['homestayTitle'] as String;
            final hLoc = item['homestayLocation'] as String;
            final clicks = item['clicks'] as int;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_work_outlined,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: hId != 'general_referral' && hId != 'explore'
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HomestayDetailsScreen(homestayId: hId),
                                ),
                              );
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hLoc.isNotEmpty)
                            Text(
                              hLoc,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$clicks clicks',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReferralAndSocialShareCard(String uid) {
    final referralLink = _getReferralLink(uid);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Homestay Link via Social Media',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Select a homestay below & share to track real-time clicks',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Homestay selector from Firestore
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('homestays')
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedHomestayId,
                    hint: const Text(
                      'Select a Homestay to Share',
                      style: TextStyle(fontSize: 12),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    items: docs.map((doc) {
                      final data = doc.data();
                      final title =
                          data['title'] as String? ?? 'Village Homestay';
                      final loc = data['location'] as String? ?? '';
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(
                          loc.isNotEmpty ? '$title ($loc)' : title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final chosen = docs.firstWhere((d) => d.id == val);
                      final data = chosen.data();
                      setState(() {
                        _selectedHomestayId = val;
                        _selectedHomestayTitle =
                            data['title'] as String? ?? 'Village Homestay';
                        _selectedHomestayLocation =
                            data['location'] as String? ?? 'Sri Lanka';
                        _selectedHomestayPrice =
                            (data['pricePerNight'] as num?)?.toDouble() ?? 4500;
                      });
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    referralLink,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _shareHomestayViaPlatform(
                    uid: uid,
                    platform: 'copy',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Copy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialButton(
                uid: uid,
                icon: Icons.chat_bubble_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                platform: 'whatsapp',
              ),
              _buildSocialButton(
                uid: uid,
                icon: Icons.facebook_rounded,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                platform: 'facebook',
              ),
              _buildSocialButton(
                uid: uid,
                icon: Icons.camera_alt_rounded,
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                platform: 'instagram',
              ),
              _buildSocialButton(
                uid: uid,
                icon: Icons.more_horiz_rounded,
                label: 'More',
                color: AppColors.primaryDark,
                platform: 'other',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String uid,
    required IconData icon,
    required String label,
    required Color color,
    required String platform,
  }) {
    return GestureDetector(
      onTap: () => _shareHomestayViaPlatform(uid: uid, platform: platform),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
