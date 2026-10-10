import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../services/auth_service.dart';
import '../../../../widgets/common/auth/auth_text_field.dart';
import '../../../../widgets/common/auth/role_selector.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserCredential userCredential;
  final String authProvider; // 'google' or 'phone'
  final String? phoneNumber;
  final String? email;
  final String? fullName;
  final String? profileImageUrl;
  final String defaultRole;

  const CompleteProfileScreen({
    super.key,
    required this.userCredential,
    required this.authProvider,
    this.phoneNumber,
    this.email,
    this.fullName,
    this.profileImageUrl,
    this.defaultRole = 'traveler',
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedRole;

  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _phoneController = TextEditingController(text: widget.phoneNumber ?? '');
    _selectedRole = widget.defaultRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.createUserProfile(
        uid: widget.userCredential.user!.uid,
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        role: _selectedRole,
        profileImageUrl: widget.profileImageUrl,
        authProvider: widget.authProvider,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complete Profile',
          style: TextStyle(color: AppColors.primaryDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Just a few more details...',
                      style: AppTextStyles.screenHeading.copyWith(
                        color: AppColors.primaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RoleSelector(
                      selectedRole: _selectedRole,
                      onRoleSelected: (role) {
                        setState(() => _selectedRole = role);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          AuthTextField(
                            label: 'Full Name *',
                            hint: 'e.g. Kasuni Perera',
                            controller: _nameController,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 20,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name.';
                              }
                              return null;
                            },
                          ),
                          AuthTextField(
                            label: 'Email Address',
                            hint: 'name@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                            ),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              if (value != null &&
                                  value.isNotEmpty &&
                                  _selectedRole != 'admin' &&
                                  !value.toLowerCase().endsWith('@gmail.com')) {
                                return 'Only @gmail.com addresses are allowed.';
                              }
                              return null;
                            },
                          ),
                          AuthTextField(
                            label: 'Phone Number',
                            hint: '+94771234567',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _completeRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Complete Registration >',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
