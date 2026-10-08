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
      return const Center(child: Text('Please sign in to view profile'));
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
            const Text('Unable to load your profile.'),
            TextButton(
              onPressed: () {},
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
          _buildReviewsSection(),
          const SizedBox(height: AppSpacing.xxl),
          _buildAccountPreferences(context, userModel, currentUser),
          const SizedBox(height: AppSpacing.xxl),
          _buildSignOutSection(context),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Reviews & Experiences',
              style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark),
            ),
            Text(
              'View All (0)',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              const Icon(Icons.rate_review_outlined, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No reviews yet',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your reviews and experiences will appear here after your stays.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountPreferences(BuildContext context, UserModel user, User firebaseAuthUser) {
    String email = user.email.isNotEmpty ? user.email : (firebaseAuthUser.email ?? 'No email');
    String phone = user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not added';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account & Preferences',
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
                Icons.person_outline, 
                'Personal Information',
                '$email • $phone',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(userModel: user)),
                  );
                },
              ),
              const Divider(height: 1),
              _buildPreferenceRow(
                Icons.trending_up_outlined, 
                'Promoter & Referral Analytics',
                'Track clicks, rewards & Rs. 0 available credit',
              ),
              const Divider(height: 1),
              _buildPreferenceRow(
                Icons.favorite_border, 
                'Saved Sanctuary Homestays',
                '0 wishlist items saved',
              ),
              const Divider(height: 1),
              _buildPreferenceRow(
                Icons.map_outlined, 
                'Downloaded Offline Guides',
                'No active trails',
                trailingBadge: 'None',
              ),
              const Divider(height: 1),
              _buildPreferenceRow(
                Icons.credit_card_outlined, 
                'Payment & Bank Accounts',
                'Not linked',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceRow(IconData icon, String title, String subtitle, {String? trailingBadge, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
      title: Text(title, style: AppTextStyles.labelLarge),
      subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3E9),
                border: Border.all(color: const Color(0xFFC8E6C9)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                trailingBadge,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        ],
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
          'Sign Out',
          style: AppTextStyles.buttonText.copyWith(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          side: const BorderSide(color: AppColors.error, width: 1),
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
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
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
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
            'profileImageUrl': newImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          await currentUser.updatePhotoURL(newImageUrl);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Change Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 80,
                  );
                  if (image != null) _updateImage(image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.userModel.fullName.isNotEmpty ? widget.userModel.fullName : (widget.firebaseAuthUser.displayName ?? 'Traveler');
    String imageUrl = (widget.userModel.profileImageUrl != null && widget.userModel.profileImageUrl!.isNotEmpty) 
      ? widget.userModel.profileImageUrl! 
      : (widget.firebaseAuthUser.photoURL ?? '');
    String location = (widget.userModel.country != null && widget.userModel.country!.isNotEmpty) ? widget.userModel.country! : 'Not added';
    
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
          // Subtle green decorative blob in top right (updated to match design)
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
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Villages Visited', '0')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildStatCard('Completed Stays', '0')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildStatCard(
                        'Guest Rating', 
                        '—', 
                        isRating: true,
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

  Widget _buildStatCard(String title, String value, {bool isRating = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRating)
                const Icon(Icons.star, color: AppColors.secondary, size: 16),
              if (isRating)
                const SizedBox(width: 4),
              Text(
                value,
                style: AppTextStyles.sectionHeading.copyWith(
                  color: isRating ? AppColors.secondary : AppColors.primaryDark,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
