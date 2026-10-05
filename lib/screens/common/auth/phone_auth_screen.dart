import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../services/auth_service.dart';
import '../../../../widgets/common/auth/international_phone_field.dart';
import 'otp_verification_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  final bool isSignUp;
  final String? defaultRole;

  const PhoneAuthScreen({
    super.key,
    this.isSignUp = false,
    this.defaultRole,
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _authService = AuthService();
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _sendOtp() async {
    if (_completePhoneNumber.isEmpty || _completePhoneNumber.length < 9) {
      _showError('Please enter a valid phone number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: _completePhoneNumber,
        onVerificationCompleted: (credential) async {
          // Auto-verification handled in OtpVerificationScreen or automatically resolves
          // In most cases on Android it auto-resolves, but we push the OTP screen anyway
        },
        onVerificationFailed: (error) {
          if (mounted) {
            setState(() => _isLoading = false);
            String errorMsg = 'Failed to send OTP. Please try again.';
            if (error.code == 'too-many-requests') {
              errorMsg = 'Too many attempts. Please try again later.';
            } else if (error.code == 'invalid-phone-number') {
              errorMsg = 'The phone number is invalid.';
            }
            _showError(errorMsg);
          }
        },
        onCodeSent: (verificationId, forceResendingToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  verificationId: verificationId,
                  phoneNumber: _completePhoneNumber,
                  isSignUp: widget.isSignUp,
                  defaultRole: widget.defaultRole,
                ),
              ),
            );
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          // Timeout handling
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                color: Colors.white,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Phone Authentication',
          style: TextStyle(color: AppColors.primaryDark),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isSignUp ? 'Sign Up with Phone' : 'Sign In with Phone',
                style: AppTextStyles.screenHeading.copyWith(
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Enter your phone number to receive a verification code.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              InternationalPhoneField(
                controller: _phoneController,
                onChanged: (phone) {
                  _completePhoneNumber = phone.completeNumber;
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Send OTP >',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
