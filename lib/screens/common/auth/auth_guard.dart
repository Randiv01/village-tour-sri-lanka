import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import 'sign_in_screen.dart';

class AuthGuard {
  /// Checks if a user is authenticated.
  /// If yes, executes [onAuthenticated].
  /// If no, shows a bottom sheet prompting the user to sign in or create an account.
  static void requireAuth({
    required BuildContext context,
    required VoidCallback onAuthenticated,
  }) {
    if (FirebaseAuth.instance.currentUser != null) {
      onAuthenticated();
    } else {
      _showSignInPrompt(context);
    }
  }

  static void _showSignInPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sign in to continue',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionHeading.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create an account or sign in to manage your bookings and personal activities.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign In / Create Account', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
