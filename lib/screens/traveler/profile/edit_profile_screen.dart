import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_radius.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userModel;

  const EditProfileScreen({super.key, required this.userModel});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _cloudinaryService = CloudinaryService();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _languagesController;
  late TextEditingController _specializationController;
  late TextEditingController _bioController;

  bool _isLoading = false;
  bool _removePhoto = false;
  XFile? _selectedImage;

  // Initial field values to detect unsaved changes
  late String _initName;
  late String _initPhone;
  late String _initLocation;
  late String _initLanguages;
  late String _initSpecialization;
  late String _initBio;

  @override
  void initState() {
    super.initState();
    final authUser = FirebaseAuth.instance.currentUser;
    
    _initName = widget.userModel.fullName.isNotEmpty
        ? widget.userModel.fullName
        : (authUser?.displayName ?? '');
    _initPhone = widget.userModel.phoneNumber;
    _initLocation = widget.userModel.country ?? '';
    _initLanguages = (widget.userModel.languages ?? []).join(', ');
    _initSpecialization = widget.userModel.specialization ?? '';
    _initBio = widget.userModel.bio ?? '';

    _nameController = TextEditingController(text: _initName);
    _phoneController = TextEditingController(text: _initPhone);
    _locationController = TextEditingController(text: _initLocation);
    _languagesController = TextEditingController(text: _initLanguages);
    _specializationController = TextEditingController(text: _initSpecialization);
    _bioController = TextEditingController(text: _initBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _languagesController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (_selectedImage != null || _removePhoto) return true;
    if (_nameController.text.trim() != _initName) return true;
    if (_phoneController.text.trim() != _initPhone) return true;
    if (_locationController.text.trim() != _initLocation) return true;
    if (_languagesController.text.trim() != _initLanguages) return true;
    if (_specializationController.text.trim() != _initSpecialization) return true;
    if (_bioController.text.trim() != _initBio) return true;
    return false;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges || _isLoading) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Text('Discard Changes?', style: AppTextStyles.labelLarge.copyWith(fontSize: 18, color: AppColors.primaryDark)),
        content: Text('Your changes have not been saved.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
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
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
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
                  title: Text('Choose from Gallery', style: AppTextStyles.labelLarge),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedImage = image;
                        _removePhoto = false;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Take Photo', style: AppTextStyles.labelLarge),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedImage = image;
                        _removePhoto = false;
                      });
                    }
                  },
                ),
                if ((widget.userModel.profileImageUrl != null && widget.userModel.profileImageUrl!.isNotEmpty) || _selectedImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.error),
                    title: Text('Remove Photo', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _removePhoto = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'Authentication required. Please sign in again.';

      String? newImageUrl = widget.userModel.profileImageUrl;

      // Handle image deletion or upload
      if (_removePhoto) {
        newImageUrl = null;
      } else if (_selectedImage != null) {
        final uploadResult = await _cloudinaryService.uploadImage(_selectedImage!);
        if (uploadResult != null) {
          newImageUrl = uploadResult.secureUrl;
        } else {
          throw 'Failed to upload image. Please try again.';
        }
      }

      // Parse languages into list
      final langList = _languagesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final updates = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'country': _locationController.text.trim(),
        'languages': langList,
        'specialization': _specializationController.text.trim(),
        'bio': _bioController.text.trim(),
        'profileImageUrl': newImageUrl,
      };

      await _authService.updateUserProfile(
        uid: currentUser.uid,
        data: updates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAuthUser = FirebaseAuth.instance.currentUser;
    final String currentImageUrl = !_removePhoto
        ? (_selectedImage != null
            ? ''
            : (widget.userModel.profileImageUrl ?? currentAuthUser?.photoURL ?? ''))
        : '';

    return PopScope(
      canPop: !_hasUnsavedChanges || _isLoading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'Edit Profile',
            style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.primaryDark),
            onPressed: () async {
              if (await _onWillPop() && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: AppSpacing.md),
                    Text('Saving changes...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar Header
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showImageOptions,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 54,
                                    backgroundColor: AppColors.softSecondarySurface,
                                    backgroundImage: _selectedImage != null
                                        ? FileImage(File(_selectedImage!.path))
                                        : (currentImageUrl.isNotEmpty
                                            ? NetworkImage(currentImageUrl)
                                            : null) as ImageProvider?,
                                    child: (_selectedImage == null && currentImageUrl.isEmpty)
                                        ? const Icon(Icons.person, size: 54, color: AppColors.textSecondary)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDark,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextButton.icon(
                              onPressed: _showImageOptions,
                              icon: const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                              label: Text('Change Profile Photo', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Personal Info Card
                      _buildSectionHeader('Personal Information'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildCardWrapper([
                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'e.g. Kasuni Perera',
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Email (Read-Only)
                        TextFormField(
                          initialValue: widget.userModel.email.isNotEmpty
                              ? widget.userModel.email
                              : (currentAuthUser?.email ?? '—'),
                          readOnly: true,
                          enabled: false,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          decoration: _inputDecoration(
                            labelText: 'Email Address (Read-only)',
                            prefixIcon: Icons.email_outlined,
                            suffixIcon: Icons.lock_outline,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration(
                            labelText: 'Phone Number *',
                            hintText: 'e.g. +94 77 123 4567',
                            prefixIcon: Icons.phone_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a valid phone number.';
                            }
                            if (value.trim().length < 7) {
                              return 'Please enter a valid phone number.';
                            }
                            return null;
                          },
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.xl),

                      // Location & Guide Info Card
                      _buildSectionHeader('Location & Languages'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildCardWrapper([
                        // Location
                        TextFormField(
                          controller: _locationController,
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration(
                            labelText: 'Location / City *',
                            hintText: 'e.g. Kandy, Sri Lanka',
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your location.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Languages
                        TextFormField(
                          controller: _languagesController,
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration(
                            labelText: 'Languages Spoken',
                            hintText: 'e.g. English, Sinhala, Tamil',
                            prefixIcon: Icons.language_outlined,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Specialization / Guide Type
                        TextFormField(
                          controller: _specializationController,
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration(
                            labelText: 'Guide Specialization / Type',
                            hintText: 'e.g. Cultural Tours, Wildlife & Nature',
                            prefixIcon: Icons.work_outline,
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.xl),

                      // Bio Section
                      _buildSectionHeader('About / Bio'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildCardWrapper([
                        TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration(
                            labelText: 'Bio / Description',
                            hintText: 'Share a brief intro about yourself, your guiding experience, or travel interests...',
                            prefixIcon: Icons.badge_outlined,
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.xxl),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.inputButtonRadius),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCardWrapper(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: AppColors.textSecondary, size: 18) : null,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputButtonRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputButtonRadius,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputButtonRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputButtonRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
