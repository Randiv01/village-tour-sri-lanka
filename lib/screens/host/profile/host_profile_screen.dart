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
import '../../../../services/host_language_service.dart';
import '../../traveler/profile/edit_profile_screen.dart';

class HostProfileScreen extends StatelessWidget {
  const HostProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Please sign in to view your profile')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        UserModel? userModel;
        if (snapshot.hasData &&
            snapshot.data!.exists &&
            snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          userModel = UserModel.fromMap(data, snapshot.data!.id);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              HostTranslation.hostProfileTitle,
              style: AppTextStyles.screenHeading.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
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
    User currentUser,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (snapshot.hasError || userModel == null) {
      return const Center(child: Text('Unable to load your profile.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HostIdentityCard(userModel: userModel, firebaseAuthUser: currentUser),
          const SizedBox(height: AppSpacing.xxl),
          _buildSupportSection(context, userModel, currentUser),
          const SizedBox(height: AppSpacing.xxl),
          _buildSignOutSection(context),
          const SizedBox(height: AppSpacing.md),
          _buildDeleteAccountSection(context),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSupportSection(
    BuildContext context,
    UserModel user,
    User firebaseAuthUser,
  ) {
    final String email = user.email.isNotEmpty
        ? user.email
        : (firebaseAuthUser.email ?? 'Not added');
    final String phone = user.phoneNumber.isNotEmpty
        ? user.phoneNumber
        : 'Not added';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          HostTranslation.accountAndPrefs,
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              _buildPreferenceRow(
                Icons.person_outline,
                HostTranslation.personalInfo,
                '$email • $phone',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(userModel: user),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceRow(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EBE1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5A7162), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.primaryDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing:
          trailingWidget ??
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 20,
          ),
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
          HostTranslation.signOut,
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

  Widget _buildDeleteAccountSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showDeleteAccountConfirmation(context);
        },
        icon: const Icon(Icons.delete_forever, color: Colors.white, size: 20),
        label: Text(
          HostTranslation.deleteAccount,
          style: AppTextStyles.buttonText.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                HostTranslation.deleteAccountConfirmTitle,
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 18,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          HostTranslation.deleteAccountConfirmMsg,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              HostTranslation.cancel,
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final navigator = Navigator.of(context, rootNavigator: true);
              final messenger = ScaffoldMessenger.of(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                useRootNavigator: true,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.error),
                ),
              );

              try {
                await AuthService().deleteAccount();
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(HostTranslation.deleteAccountSuccess),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            label: Text(HostTranslation.deleteBtn),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Text(
          HostTranslation.signOutConfirmTitle,
          style: AppTextStyles.labelLarge.copyWith(
            fontSize: 18,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          HostTranslation.signOutConfirmMsg,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              HostTranslation.cancel,
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(HostTranslation.signOut),
          ),
        ],
      ),
    );
  }
}

class _HostIdentityCard extends StatefulWidget {
  final UserModel userModel;
  final User firebaseAuthUser;

  const _HostIdentityCard({
    required this.userModel,
    required this.firebaseAuthUser,
  });

  @override
  State<_HostIdentityCard> createState() => _HostIdentityCardState();
}

class _HostIdentityCardState extends State<_HostIdentityCard> {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update image')));
    } finally {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  Future<void> _removeImage() async {
    setState(() => _isLoadingImage = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'profileImageUrl': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        await currentUser.updatePhotoURL(null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to remove image')));
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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
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
                if (widget.userModel.profileImageUrl != null &&
                    widget.userModel.profileImageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    title: Text(
                      'Remove Photo',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.error,
                      ),
                    ),
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
        : (widget.firebaseAuthUser.displayName ?? 'Host');

    final String imageUrl =
        (widget.userModel.profileImageUrl != null &&
            widget.userModel.profileImageUrl!.isNotEmpty)
        ? widget.userModel.profileImageUrl!
        : (widget.firebaseAuthUser.photoURL ?? '');

    final String location = widget.userModel.location.isNotEmpty
        ? widget.userModel.location
        : 'Not added';

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
          ),
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
                            backgroundImage: imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: AppColors.textSecondary,
                                  )
                                : null,
                          ),
                          if (_isLoadingImage)
                            const Positioned.fill(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryDark,
                              ),
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
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 12,
                              ),
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
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  HostTranslation.homestayHost,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
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
