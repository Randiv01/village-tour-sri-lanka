import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../../theme/app_colors.dart';

class InternationalPhoneField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isRequired;
  final void Function(PhoneNumber)? onChanged;

  const InternationalPhoneField({
    super.key,
    required this.controller,
    this.label = 'Phone Number',
    this.hint = '77 123 4567',
    this.isRequired = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label.replaceAll(' *', ''),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Work Sans',
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          IntlPhoneField(
            controller: controller,
            initialCountryCode: 'LK',
            invalidNumberMessage: 'Please enter a valid phone number.',
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            // disableLengthCheck: false is the default, which automatically restricts typing beyond max length!
            flagsButtonPadding: const EdgeInsets.only(left: 12),
            showDropdownIcon: true,
            dropdownIconPosition: IconPosition.trailing,
            dropdownIcon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
