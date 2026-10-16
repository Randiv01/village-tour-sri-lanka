import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum StatusDialogType {
  success,
  error,
  warning,
  info,
}

class AppStatusDialog extends StatelessWidget {
  final StatusDialogType type;
  final String title;
  final String message;
  final List<String>? details;
  final Widget? customContent;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const AppStatusDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.details,
    this.customContent,
    this.primaryButtonText = 'Done',
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
  });

  /// Show a Success Dialog (Green badge with checkmark)
  static Future<bool?> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    List<String>? details,
    Widget? customContent,
    String buttonText = 'Done',
    VoidCallback? onPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    return show(
      context: context,
      type: StatusDialogType.success,
      title: title,
      message: message,
      details: details,
      customContent: customContent,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
      secondaryButtonText: secondaryButtonText,
      onSecondaryPressed: onSecondaryPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show an Error Dialog (Red badge with cancel/error icon)
  static Future<bool?> showError({
    required BuildContext context,
    required String title,
    required String message,
    List<String>? details,
    Widget? customContent,
    String buttonText = 'Done',
    VoidCallback? onPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    return show(
      context: context,
      type: StatusDialogType.error,
      title: title,
      message: message,
      details: details,
      customContent: customContent,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
      secondaryButtonText: secondaryButtonText,
      onSecondaryPressed: onSecondaryPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show a Warning Dialog (Amber badge with warning icon)
  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    List<String>? details,
    Widget? customContent,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    return show(
      context: context,
      type: StatusDialogType.warning,
      title: title,
      message: message,
      details: details,
      customContent: customContent,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
      secondaryButtonText: secondaryButtonText,
      onSecondaryPressed: onSecondaryPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show an Info Dialog (Blue badge with info icon)
  static Future<bool?> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    List<String>? details,
    Widget? customContent,
    String buttonText = 'Done',
    VoidCallback? onPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    return show(
      context: context,
      type: StatusDialogType.info,
      title: title,
      message: message,
      details: details,
      customContent: customContent,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
      secondaryButtonText: secondaryButtonText,
      onSecondaryPressed: onSecondaryPressed,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Generic display method with smooth pop animation
  static Future<bool?> show({
    required BuildContext context,
    required StatusDialogType type,
    required String title,
    required String message,
    List<String>? details,
    Widget? customContent,
    String primaryButtonText = 'Done',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppStatusDialog(
        type: type,
        title: title,
        message: message,
        details: details,
        customContent: customContent,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: () {
          Navigator.pop(ctx, true);
          if (onPrimaryPressed != null) {
            onPrimaryPressed();
          }
        },
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: () {
          Navigator.pop(ctx, false);
          if (onSecondaryPressed != null) {
            onSecondaryPressed();
          }
        },
      ),
    );
  }

  Color get _badgeBgColor {
    switch (type) {
      case StatusDialogType.success:
        return const Color(0xFFE8F5E9);
      case StatusDialogType.error:
        return const Color(0xFFFFEBEE);
      case StatusDialogType.warning:
        return const Color(0xFFFFF8E1);
      case StatusDialogType.info:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get _iconColor {
    switch (type) {
      case StatusDialogType.success:
        return const Color(0xFF2E7D32);
      case StatusDialogType.error:
        return const Color(0xFFC62828);
      case StatusDialogType.warning:
        return const Color(0xFFF57F17);
      case StatusDialogType.info:
        return const Color(0xFF1976D2);
    }
  }

  IconData get _iconData {
    switch (type) {
      case StatusDialogType.success:
        return Icons.check_circle_outline;
      case StatusDialogType.error:
        return Icons.cancel_outlined;
      case StatusDialogType.warning:
        return Icons.warning_amber_rounded;
      case StatusDialogType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color get _buttonColor {
    switch (type) {
      case StatusDialogType.error:
        return const Color(0xFFC62828);
      case StatusDialogType.success:
      case StatusDialogType.warning:
      case StatusDialogType.info:
        return const Color(0xFF2E4F42);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Circle icon badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _badgeBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconData,
              color: _iconColor,
              size: 48,
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 8),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          // Optional detail items
          if (details != null && details!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5EE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDD5C0)),
              ),
              child: Column(
                children: details!.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          if (customContent != null) ...[
            const SizedBox(height: 12),
            customContent!,
          ],

          const SizedBox(height: 20),

          // Primary Done/OK Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryPressed ?? () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                primaryButtonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // Optional Secondary Button
          if (secondaryButtonText != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSecondaryPressed ?? () => Navigator.pop(context, false),
                child: Text(
                  secondaryButtonText!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
