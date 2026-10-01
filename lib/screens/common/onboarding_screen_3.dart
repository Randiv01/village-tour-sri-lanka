import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  Future<void> _finish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Sign In / Auth Screen')),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/onboarding/onboarding_pattern.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(),
                        // Image Container
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: AppRadius.largeRadius,
                            child: Image.asset(
                              'assets/images/onboarding/onboarding_03.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),

                        // Title
                        Text(
                          'Stay Connected, Even Offline',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.primaryDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Description
                        Text(
                          'Chat with local hosts across English and Sinhala, and navigate village destinations even with limited connectivity.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),

                // Bottom Controls Area
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(isActive: false),
                          _buildDot(isActive: false),
                          _buildDot(isActive: true),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Get Started Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _finish(context),
                          child: const Text('Get Started →'),
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
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}
