import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../traveler/profile/edit_profile_screen.dart';

class GuideProfileScreen extends StatefulWidget {
  const GuideProfileScreen({super.key});

  @override
  State<GuideProfileScreen> createState() => _GuideProfileScreenState();
}

class _GuideProfileScreenState extends State<GuideProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final profile = await _authService.getUserProfile(uid);
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        title: Text('My Profile', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text('Could not load profile.', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                ]))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final profile = _profile;
    final authUser = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: Column(children: [
        // Profile header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.large)),
          ),
          child: Column(children: [
            // Avatar
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3)),
              child: ClipOval(
                child: profile?.profileImageUrl != null && profile!.profileImageUrl!.isNotEmpty
                    ? Image.network(profile.profileImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _defaultAvatar())
                    : _defaultAvatar(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(profile?.fullName ?? authUser?.displayName ?? 'Tour Guide', style: AppTextStyles.screenHeading.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: AppRadius.pillRadius),
              child: const Text('Tour Guide', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            if (profile?.country != null && profile!.country!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(profile.country!, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Info section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(children: [
            _sectionTitle('Contact Information'),
            const SizedBox(height: AppSpacing.sm),
            _infoCard([
              _infoItem(Icons.email_outlined, 'Email', profile?.email ?? authUser?.email ?? '—'),
              if (profile?.phoneNumber != null && profile!.phoneNumber.isNotEmpty)
                _infoItem(Icons.phone_outlined, 'Phone', profile.phoneNumber),
            ]),
            const SizedBox(height: AppSpacing.lg),

            _sectionTitle('Account Details'),
            const SizedBox(height: AppSpacing.sm),
            _infoCard([
              _infoItem(Icons.work_outline, 'Role', 'Tour Guide'),
              if (profile?.preferredLanguage != null && profile!.preferredLanguage!.isNotEmpty)
                _infoItem(Icons.language_outlined, 'Language', profile.preferredLanguage!),
            ]),
            const SizedBox(height: AppSpacing.xl),

            // Actions
            _sectionTitle('Settings'),
            const SizedBox(height: AppSpacing.sm),
            _settingsTile(Icons.edit_outlined, 'Edit Profile', AppColors.primary, () async {
              if (_profile == null) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(userModel: _profile!)),
              );
              if (result == true) {
                _loadProfile();
              }
            }),
            const SizedBox(height: AppSpacing.xl),

            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.inputButtonRadius),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ]),
        ),
      ]),
    );
  }

  Widget _defaultAvatar() => Container(color: AppColors.primary.withValues(alpha: 0.5), child: const Icon(Icons.person, color: Colors.white, size: 44));
  Widget _sectionTitle(String t) => Align(alignment: Alignment.centerLeft, child: Text(t, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)));

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardRadius, border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
    child: Column(children: [
      for (int i = 0; i < children.length; i++) ...[
        children[i],
        if (i < children.length - 1) const Divider(height: 1, color: AppColors.border),
      ],
    ]),
  );

  Widget _infoItem(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Row(children: [
      Icon(icon, size: 20, color: AppColors.textSecondary),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
      ])),
    ]),
  );

  Widget _settingsTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.inputButtonRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.inputButtonRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(borderRadius: AppRadius.inputButtonRadius, border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: AppTextStyles.labelLarge)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ]),
        ),
      ),
    );
  }
}
