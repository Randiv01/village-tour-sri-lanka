import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_radius.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../traveler/profile/edit_profile_screen.dart';

class GuideProfileScreen extends StatefulWidget {
  const GuideProfileScreen({super.key});

  @override
  State<GuideProfileScreen> createState() => _GuideProfileScreenState();
}

class _GuideProfileScreenState extends State<GuideProfileScreen> {
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  UserModel? _profile;
  bool _loading = true;
  bool _updatingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = 'User not signed in.';
          _loading = false;
        });
        return;
      }
      final profile = await _authService.getUserProfile(uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load your profile.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeProfilePhoto(ImageSource source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _updatingPhoto = true);

      final uploadResult = await _cloudinaryService.uploadImage(image);
      if (uploadResult != null) {
        await _authService.updateUserProfile(
          uid: uid,
          data: {'profileImageUrl': uploadResult.secureUrl},
        );
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingPhoto = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _updatingPhoto = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove profile photo.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingPhoto = false);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.pillRadius),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Choose from Gallery', style: AppTextStyles.labelLarge),
                  onTap: () {
                    Navigator.pop(context);
                    _changeProfilePhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Take Photo', style: AppTextStyles.labelLarge),
                  onTap: () {
                    Navigator.pop(context);
                    _changeProfilePhoto(ImageSource.camera);
                  },
                ),
                if (_profile?.profileImageUrl != null && _profile!.profileImageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.error),
                    title: Text('Remove Photo', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePhoto();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Text('Sign out?', style: AppTextStyles.labelLarge.copyWith(fontSize: 18, color: AppColors.primaryDark)),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _authService.signOut();
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Text('Delete Account', style: AppTextStyles.labelLarge.copyWith(fontSize: 18, color: AppColors.error)),
        content: Text(
          'Are you sure you want to completely delete your account? This will permanently delete your profile, bookings, packages, and personal details. This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
        
        await _authService.deleteAccount();
        
        if (mounted) {
          Navigator.pop(context); // pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          // Redirection will be handled by the root auth stream listener
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'My Profile',
          style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: AppSpacing.md),
                  Text('Loading profile...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!, style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: AppColors.primary,
                  child: _buildBody(),
                ),
    );
  }

  Widget _buildBody() {
    final profile = _profile;
    final authUser = FirebaseAuth.instance.currentUser;
    final String displayName = (profile?.fullName.isNotEmpty == true)
        ? profile!.fullName
        : (authUser?.displayName ?? 'Tour Guide');

    final String email = (profile?.email.isNotEmpty == true)
        ? profile!.email
        : (authUser?.email ?? 'Not added');

    final String phone = (profile?.phoneNumber.isNotEmpty == true)
        ? profile!.phoneNumber
        : 'Not added';

    final String location = (profile?.location.isNotEmpty == true)
        ? profile!.location
        : 'Not added';

    final String languages = (profile?.languages != null && profile!.languages!.isNotEmpty)
        ? profile.languages!.join(', ')
        : 'Not added';

    final String specialization = (profile?.specialization != null && profile!.specialization!.isNotEmpty)
        ? profile.specialization!
        : 'General Village Tours';

    final String bio = (profile?.bio != null && profile!.bio!.isNotEmpty)
        ? profile.bio!
        : '';

    final String imageUrl = (profile?.profileImageUrl != null && profile!.profileImageUrl!.isNotEmpty)
        ? profile.profileImageUrl!
        : (authUser?.photoURL ?? '');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.large)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showImageOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                        ),
                        child: ClipOval(
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => _defaultAvatar(),
                                )
                              : _defaultAvatar(),
                        ),
                      ),
                      if (_updatingPhoto)
                        const Positioned.fill(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenHeading.copyWith(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 6),

                // Role & Verification badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.explore_outlined, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Tour Guide',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (profile?.isVerified == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784).withValues(alpha: 0.3),
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Verified Guide',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                if (location != 'Not added')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: AppTextStyles.caption.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Main Profile Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                // Bio / About Me if available
                if (bio.isNotEmpty) ...[
                  _sectionTitle('About Me'),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      bio,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Contact Information
                _sectionTitle('Personal Information'),
                const SizedBox(height: AppSpacing.xs),
                _infoCard([
                  _infoItem(Icons.person_outline, 'Full Name', displayName),
                  _infoItem(Icons.email_outlined, 'Email Address', email),
                  _infoItem(Icons.phone_outlined, 'Phone Number', phone),
                ]),
                const SizedBox(height: AppSpacing.lg),

                // Guide Information
                _sectionTitle('Guide Information'),
                const SizedBox(height: AppSpacing.xs),
                _infoCard([
                  _infoItem(Icons.location_on_outlined, 'Base Location', location),
                  _infoItem(Icons.language_outlined, 'Languages Spoken', languages),
                  _infoItem(Icons.work_outline, 'Specialization', specialization),
                  _infoItem(
                    Icons.security_outlined,
                    'Account Status',
                    profile?.isActive == true ? 'Active' : 'Suspended',
                  ),
                ]),
                const SizedBox(height: AppSpacing.xl),

                // Settings & Edit Actions
                _sectionTitle('Account Actions'),
                const SizedBox(height: AppSpacing.xs),
                _actionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile Details',
                  subtitle: 'Update your name, location, languages & bio',
                  color: AppColors.primary,
                  onTap: () async {
                    if (profile == null) return;
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(userModel: profile),
                      ),
                    );
                    if (updated == true) {
                      _loadProfile();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _actionTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Change Profile Photo',
                  subtitle: 'Upload or remove your avatar picture',
                  color: AppColors.primary,
                  onTap: _showImageOptions,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.inputButtonRadius),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Delete Account Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                    label: const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.inputButtonRadius),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.4),
      child: const Icon(Icons.person, color: Colors.white, size: 50),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.inputButtonRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.inputButtonRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.inputButtonRadius,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
