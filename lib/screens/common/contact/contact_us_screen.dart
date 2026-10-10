import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_radius.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCountry = 'Select';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('GET IN TOUCH'),
              const SizedBox(height: AppSpacing.md),
              _buildContactCards(),
              const SizedBox(height: AppSpacing.xxl),
              _buildInquiryForm(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              color: Colors.white,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.primaryDark,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Column(
        children: [
          Text(
            'Contact Us',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              fontFamily: 'PlayfairDisplay', // Fallback to serifs
            ).merge(AppTextStyles.screenHeading),
          ),
          Text(
            'A BETTER LOCAL EXPERIENCE',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 18,
                color: AppColors.primaryDark,
              ),
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCards() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.phone_in_talk,
          iconBgColor: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          title: 'PHONE',
          details: '+94 71 422 6176\n+94 66 312 4564',
          actionText: 'Call',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildInfoCard(
          icon: Icons.email_outlined,
          iconBgColor: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFEF6C00),
          title: 'EMAIL',
          details: 'info@villagetoursrilanka.com\nvillagetoursrilanka.com',
          actionText: 'Write',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildInfoCard(
          icon: Icons.location_on,
          iconBgColor: const Color(0xFFE0F2F1),
          iconColor: const Color(0xFF00695C),
          title: 'ADDRESS',
          details: 'Nilagama, Bambaragaswewa\nGalewela, Sri Lanka',
          actionText: 'Map',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            height: 16,
            child: VerticalDivider(
              color: Color(0xFFE0D8C3), // A darker connector visually present in design
              thickness: 4,
              width: 10,
            ),
          ),
        ),
        _buildWhatsAppCard(),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String details,
    required String actionText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFFEAE2CD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE6), // light beige action bg
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primaryDark, width: 2), // Bold dark green/black border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF25D366), // WhatsApp exact green
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chat on WhatsApp',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+94 71 422 6176 (Fast Reply)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_right_alt, color: AppColors.primaryDark, size: 24),
        ],
      ),
    );
  }

  Widget _buildInquiryForm() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFFEAE2CD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inquiry Form',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    fontFamily: 'PlayfairDisplay', // serif styling
                  ),
                ),
                Text(
                  '* Required',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Connect with verified rural homestays across\nSri Lanka',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: Color(0xFFEAE2CD), height: 1.5),
            const SizedBox(height: AppSpacing.lg),

            _buildFormFieldLabel('NAME', required: true),
            const SizedBox(height: 8),
            _buildTextField(hintText: 'Your name'),
            const SizedBox(height: AppSpacing.lg),

            _buildFormFieldLabel('EMAIL', required: true),
            const SizedBox(height: 8),
            _buildTextField(hintText: 'name@example.com'),
            const SizedBox(height: AppSpacing.lg),

            _buildFormFieldLabel('COUNTRY', required: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEAE2CD)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountry,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  items: ['Select', 'Sri Lanka', 'United Kingdom', 'United States', 'India', 'Australia']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: value == 'Select' ? AppColors.textSecondary : AppColors.primaryDark,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCountry = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildFormFieldLabel('MESSAGE'),
            const SizedBox(height: 8),
            _buildTextField(
              hintText: 'Tell us about special requests or pickup\nneeds...',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inquiry Sent Successfully!')),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E4F42), // Dark forest green
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'SUBMIT INQUIRY FORM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFieldLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
            letterSpacing: 1.0,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red, // as per the design red asterisk
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({required String hintText, int maxLines = 1}) {
    return TextFormField(
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEAE2CD), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEAE2CD), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (hintText != 'Tell us about special requests or pickup\nneeds...') {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
        }
        return null;
      },
    );
  }
}
