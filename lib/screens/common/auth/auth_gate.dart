import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/auth_service.dart';


import '../../admin/admin_shell.dart';
import '../../host/main/host_main_screen.dart';
import '../../guide/guide_dashboard_screen.dart';
import '../../traveler/main/traveler_main_screen.dart';
import '../../../theme/app_colors.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Still checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // Not signed in -> Public Home
        if (!snapshot.hasData || snapshot.data == null) {
          return const TravelerMainScreen();
        }

        // Signed in -> Need to fetch profile to know role
        return FutureBuilder(
          future: authService.getUserProfile(snapshot.data!.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (profileSnapshot.hasError || !profileSnapshot.hasData) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          profileSnapshot.hasError 
                            ? 'Error loading profile: ${profileSnapshot.error}'
                            : 'No user profile found in the database for this account. Please ensure your Firestore document is created with the same UID as your Firebase Auth account.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.error),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => authService.signOut(),
                          child: const Text('Back to Sign In'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final user = profileSnapshot.data!;

            if (!user.isActive) {
              authService.signOut();
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Your account has been deactivated. Please contact support.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.error),
                    ),
                  ),
                ),
              );
            }

            // Route based on role
            switch (user.role) {
              case 'admin':
                return const AdminShell();
              case 'host':
                return const HostMainScreen();
              case 'guide':
                return const GuideDashboardScreen();
              case 'traveler':
              default:
                return const TravelerMainScreen();
            }
          },
        );
      },
    );
  }
}
