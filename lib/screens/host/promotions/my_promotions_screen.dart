import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';

class MyPromotionsScreen extends StatelessWidget {
  const MyPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
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
            child: const Icon(Icons.notifications_none, color: AppColors.primaryDark, size: 20),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.secondary),
                        SizedBox(width: 8),
                        Text('This\nMonth', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, height: 1.1)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              
              _buildLinkClicksCard(),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _buildBookingsCard()),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildEarningsCard()),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildEarningsOverTimeCard(),
              const SizedBox(height: AppSpacing.xl),
              _buildBookingSourcesCard(),
              const SizedBox(height: AppSpacing.xl),
              _buildReferralLinkCard(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),

        ),
      ),
    );
  }


  Widget _buildLinkClicksCard() {
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
            child: Icon(Icons.remove_red_eye, color: AppColors.primaryDark.withValues(alpha: 0.7), size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Link Clicks', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '1,420',
                      style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontSize: 28),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up, size: 10, color: Colors.green),
                          const SizedBox(width: 2),
                          Text('+12%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: const [
              SizedBox(height: 24),
              Text('vs prev wk', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsCard() {
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
              const Text('Bookings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: AppColors.primaryDark, size: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '38',
            style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontSize: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('Confirmed stays', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
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
              const Text('Earnings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.secondary, size: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Rs. ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              Text(
                '19,500',
                style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.arrow_upward, size: 10, color: Colors.green),
              Text('+18.4% growth', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsOverTimeCard() {
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
          Text('Earnings Over Time\n(Daily)', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontSize: 16, height: 1.2)),
          const SizedBox(height: 4),
          const Text('Daily village booking payouts (LKR)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 24),
          
          // Chart Graphic
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar('Mon', '1.8k', 0.4, AppColors.softSecondarySurface, false),
                    _buildBar('Tue', '2.2k', 0.1, const Color(0xFFF4F0E8), false),
                    _buildBar('Wed', '1.5k', 0.35, AppColors.softSecondarySurface, false),
                    _buildBar('Thu', '2.9k', 0.6, AppColors.primaryDark, false),
                    _buildBar('Fri', '3.4k', 0.45, AppColors.softSecondarySurface, false),
                    _buildBar('Sat', '4.8k', 0.9, AppColors.secondary, true),
                    _buildBar('Sun', '2.7k', 0.1, const Color(0xFFF4F0E8), false), // Lowest
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.primaryDark, 'Thu (Forest)'),
              const SizedBox(width: 12),
              _buildLegendItem(AppColors.secondary, 'Sat (Ochre)'),
              const SizedBox(width: 12),
              _buildLegendItem(AppColors.softSecondarySurface, 'Standard'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, String value, double heightFactor, Color color, bool isPeak) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPeak)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Peak: Sat (Rs.\n4.8k)', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, height: 1.1)),
              ],
            ),
          ),
        if (!isPeak)
          Text(value, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
        
        if (isPeak) 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(4)),
            child: const Text('Peak', style: TextStyle(fontSize: 6, color: Colors.white)),
          ),
          
        const SizedBox(height: 4),
        Container(
          width: 20,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: TextStyle(fontSize: 10, fontWeight: isPeak ? FontWeight.bold : FontWeight.normal, color: isPeak ? AppColors.secondary : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildBookingSourcesCard() {
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
              Text('Booking Sources', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontSize: 16)),
              const Text('1,420 total clicks', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSourceItem(Icons.video_library_outlined, 'Instagram Travel Vlog Link', '54%', 0.54, AppColors.primaryDark),
          const SizedBox(height: AppSpacing.md),
          _buildSourceItem(Icons.qr_code_2_outlined, 'Direct QR Code at Homestay', '28%', 0.28, AppColors.secondary),
          const SizedBox(height: AppSpacing.md),
          _buildSourceItem(Icons.chat_bubble_outline, 'WhatsApp Village Group', '18%', 0.18, AppColors.secondary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Widget _buildSourceItem(IconData icon, String title, String percentage, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            Text(percentage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFF4F0E8),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildReferralLinkCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0E8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gamgedara Referral Link', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13)),
                const Text('gamgedara.lk/promo/kandy-terrace', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Copy', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

}
