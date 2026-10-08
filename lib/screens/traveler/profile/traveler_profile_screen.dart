import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_radius.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/cloudinary_service.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class TravelerProfileScreen extends StatelessWidget {
  final VoidCallback? onBackTap;

  const TravelerProfileScreen({super.key, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text('Please sign in to view your profile', style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        UserModel? userModel;
        if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          userModel = UserModel.fromMap(data, snapshot.data!.id);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'User Profile',
              style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark),
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
            leading: onBackTap != null
                ? Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.primaryDark),
                      ),
                      onPressed: onBackTap,
                    ),
                  )
                : null,
            actions: [
              if (userModel != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.settings_outlined, size: 18, color: AppColors.primaryDark),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ),
            ],
          ),
          body: _buildBody(context, snapshot, userModel, currentUser),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, 
    AsyncSnapshot<DocumentSnapshot> snapshot, 
    UserModel? userModel, 
    User currentUser
  ) {
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Unable to load your profile.', style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
            ),
          ],
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: AppSpacing.md),
            Text('Loading profile...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (userModel == null) {
      return const Center(child: Text('Profile not found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IdentityCard(userModel: userModel, firebaseAuthUser: currentUser),
          const SizedBox(height: AppSpacing.xxl),
          _buildPersonalInformationSection(context, userModel, currentUser),
          const SizedBox(height: AppSpacing.xxl),
          _buildAccountPreferencesSection(context, userModel, currentUser),
          const SizedBox(height: AppSpacing.xxl),
          _buildSignOutSection(context),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildPersonalInformationSection(BuildContext context, UserModel user, User firebaseAuthUser) {
    final String email = user.email.isNotEmpty ? user.email : (firebaseAuthUser.email ?? 'Not added');
    final String phone = user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not added';
    final String location = user.location.isNotEmpty ? user.location : 'Not added';
    final String languages = (user.languages != null && user.languages!.isNotEmpty) ? user.languages!.join(', ') : 'Not added';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personal Information',
              style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(userModel: user)),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
              label: Text('Edit', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.person_outline, 'Full Name', user.fullName.isNotEmpty ? user.fullName : (firebaseAuthUser.displayName ?? 'Traveler')),
              const Divider(height: 1, color: AppColors.border),
              _buildInfoRow(Icons.email_outlined, 'Email Address', email),
              const Divider(height: 1, color: AppColors.border),
              _buildInfoRow(Icons.phone_outlined, 'Phone Number', phone),
              const Divider(height: 1, color: AppColors.border),
              _buildInfoRow(Icons.location_on_outlined, 'Location', location),
              if (languages != 'Not added') ...[
                const Divider(height: 1, color: AppColors.border),
                _buildInfoRow(Icons.language_outlined, 'Languages Spoken', languages),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
                Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPreferencesSection(BuildContext context, UserModel user, User firebaseAuthUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account & Settings',
          style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              _buildPreferenceRow(
                Icons.edit_outlined, 
                'Edit Profile Details',
                'Update your name, contact info & location',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(userModel: user)),
                  );
                },
              ),
              const Divider(height: 1),
              _buildPreferenceRow(
                Icons.settings_outlined, 
                'App Settings',
                'Notifications, security & app options',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceRow(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
      title: Text(title, style: AppTextStyles.labelLarge),
      subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildSignOutSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showSignOutConfirmation(context);
        },
        icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
        label: Text(
          'Sign Out',
          style: AppTextStyles.buttonText.copyWith(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
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
  }
}

class _IdentityCard extends StatefulWidget {
  final UserModel userModel;
  final User firebaseAuthUser;

  const _IdentityCard({required this.userModel, required this.firebaseAuthUser});

  @override
  State<_IdentityCard> createState() => _IdentityCardState();
}

class _IdentityCardState extends State<_IdentityCard> {
  bool _isLoadingImage = false;

  Future<void> _updateImage(XFile image) async {
    setState(() => _isLoadingImage = true);
    try {
      final cloudinaryService = CloudinaryService();
      final uploadResult = await cloudinaryService.uploadImage(image);
      if (uploadResult != null) {
        final newImageUrl = uploadResult.secureUrl;
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await AuthService().updateUserProfile(
            uid: currentUser.uid,
            data: {'profileImageUrl': newImageUrl},
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update image')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  Future<void> _removeImage() async {
    setState(() => _isLoadingImage = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'profileImageUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await currentUser.updatePhotoURL(null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove image')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingImage = false);
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
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.pillRadius),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Change Photo', style: AppTextStyles.labelLarge),
                  onTap: () async {
                    Navigator.pop(context);
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (image != null) _updateImage(image);
                  },
                ),
                if (widget.userModel.profileImageUrl != null && widget.userModel.profileImageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.error),
                    title: Text('Remove Photo', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.userModel.fullName.isNotEmpty
        ? widget.userModel.fullName
        : (widget.firebaseAuthUser.displayName ?? 'Traveler');

    final String imageUrl = (widget.userModel.profileImageUrl != null && widget.userModel.profileImageUrl!.isNotEmpty) 
        ? widget.userModel.profileImageUrl! 
        : (widget.firebaseAuthUser.photoURL ?? '');

    final String location = widget.userModel.location.isNotEmpty ? widget.userModel.location : 'Not added';
    
    String roleDisplay = 'Traveler';
    if (widget.userModel.role == 'host') roleDisplay = 'Homestay Host';
    if (widget.userModel.role == 'guide') roleDisplay = 'Tour Guide';
    if (widget.userModel.role == 'admin') roleDisplay = 'Administrator';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3E9).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showImageOptions,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.softSecondarySurface,
                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty 
                                ? const Icon(Icons.person, size: 36, color: AppColors.textSecondary)
                                : null,
                          ),
                          if (_isLoadingImage)
                            const Positioned.fill(
                              child: CircularProgressIndicator(color: AppColors.primaryDark),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.screenHeading.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.person_outline, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  roleDisplay,
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
