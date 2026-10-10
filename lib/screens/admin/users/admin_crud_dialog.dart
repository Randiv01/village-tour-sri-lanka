import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../models/user_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

class UserCrudDialog extends StatefulWidget {
  final UserModel? user;
  final String role;

  const UserCrudDialog({super.key, this.user, required this.role});

  @override
  State<UserCrudDialog> createState() => _UserCrudDialogState();
}

class _UserCrudDialogState extends State<UserCrudDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController();
  final _languageController = TextEditingController();
  final _specializationController = TextEditingController();
  final _bioController = TextEditingController();
  final _languagesController = TextEditingController();
  bool _isPasswordObscured = true;

  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _phoneController.text = widget.user!.phoneNumber;
      _isActive = widget.user!.isActive;
      _countryController.text = widget.user!.country ?? '';
      _languageController.text = widget.user!.preferredLanguage ?? '';
      _specializationController.text = widget.user!.specialization ?? '';
      _bioController.text = widget.user!.bio ?? '';
      _languagesController.text = widget.user!.languages?.join(', ') ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countryController.dispose();
    _languageController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _languagesController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isUpdating = widget.user != null;
      final email = _emailController.text.trim();

      String displayRole =
          widget.role.substring(0, 1).toUpperCase() + widget.role.substring(1);

      if (isUpdating) {
        // Update existing profile
        final Map<String, dynamic> updateData = {
          'fullName': _nameController.text.trim(),
          'email': email,
          'phoneNumber': _phoneController.text.trim(),
          'isActive': _isActive,
          'country': _countryController.text.trim(),
          'preferredLanguage': _languageController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (widget.role == 'guide' || widget.role == 'host') {
          updateData['bio'] = _bioController.text.trim();
        }
        if (widget.role == 'guide') {
          updateData['specialization'] = _specializationController.text.trim();
          updateData['languages'] = _languagesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user!.uid)
            .update(updateData);
      } else {
        // Create new admin authentication via a temporary Firebase App
        // This avoids logging out the current admin!
        final tempApp = await Firebase.initializeApp(
          name: 'tempAdminCreator',
          options: Firebase.app().options,
        );

        final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
        final cred = await tempAuth.createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );
        final uid = cred.user!.uid;

        // Clean up the temp app
        await tempApp.delete();

        final newDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid);

        final newUser = UserModel(
          uid: uid,
          email: email,
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          role: widget.role,
          isActive: _isActive,
          isEmailVerified: false,
          country: _countryController.text.trim(),
          preferredLanguage: _languageController.text.trim(),
          bio: (widget.role == 'guide' || widget.role == 'host') ? _bioController.text.trim() : null,
          specialization: widget.role == 'guide' ? _specializationController.text.trim() : null,
          languages: widget.role == 'guide' ? _languagesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await newDocRef.set(newUser.toMap());
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdating
                  ? '$displayRole updated'
                  : '$displayRole profile created',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving ${widget.role}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = widget.user != null;
    String displayRole =
        widget.role.substring(0, 1).toUpperCase() + widget.role.substring(1);

    return AlertDialog(
      title: Text(isUpdating ? 'Edit $displayRole' : 'Add $displayRole'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  if (val.trim().length < 3) return 'Name must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (!val.contains('@')) return 'Invalid email';
                  if (widget.role == 'admin' &&
                      !val.endsWith('@villagetour.com')) {
                    return 'Must use @villagetour.com domain';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (!RegExp(r'^\+?[\d\s\-]{9,15}$').hasMatch(val)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _languageController,
                decoration: const InputDecoration(
                  labelText: 'Preferred Language *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              if (widget.role == 'guide' || widget.role == 'host') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
              if (widget.role == 'guide') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Specialization *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Required for guides' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _languagesController,
                  decoration: const InputDecoration(
                    labelText: 'Languages (comma separated) *',
                    border: OutlineInputBorder(),
                    hintText: 'eg: English, Sinhala',
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Required for guides' : null,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: const Text('Is Active'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                activeThumbColor: AppColors.primary,
              ),
              if (!isUpdating) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isPasswordObscured,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}






