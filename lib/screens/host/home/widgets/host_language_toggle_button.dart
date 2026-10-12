import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../services/host_language_service.dart';

class HostLanguageToggleButton extends StatelessWidget {
  const HostLanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: HostLanguageService().isSinhalaNotifier,
      builder: (context, isSinhala, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HostLanguageService().toggleLanguage();
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryDark.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language,
                      color: AppColors.primaryDark,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'සිංහල /',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.1,
                          fontWeight:
                              isSinhala ? FontWeight.w800 : FontWeight.w500,
                          color: isSinhala
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'English',
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.1,
                          fontWeight:
                              !isSinhala ? FontWeight.w800 : FontWeight.w500,
                          color: !isSinhala
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
