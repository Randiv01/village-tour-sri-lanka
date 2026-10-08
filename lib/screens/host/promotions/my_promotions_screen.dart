import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../home/widgets/analytics_stat_card.dart';

class MyPromotionsScreen extends StatelessWidget {
  const MyPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Promotion Analytics', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Stats', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AnalyticsStatCard(
                    topIcon: Icons.local_offer,
                    title: 'Active Promos',
                    value: '3',
                    bottomWidget: const Text('Running now', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AnalyticsStatCard(
                    topIcon: Icons.group_add,
                    title: 'New Bookings',
                    value: '+14',
                    bottomWidget: const Text('Via promotions', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            Text('Performance Overview', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bar_chart, size: 64, color: AppColors.secondary),
                    SizedBox(height: 8),
                    Text('Earnings Chart Representation', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            Text('Referral Links', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark)),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppColors.primaryDark),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text('villagetour.com/ref/host-promo-2026', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('COPY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
