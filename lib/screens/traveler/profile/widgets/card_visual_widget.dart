import 'package:flutter/material.dart';

class CardVisualThemes {
  static const List<CardVisualThemeData> themes = [
    // 0: Ceylon Emerald
    CardVisualThemeData(
      name: 'Emerald Forest',
      gradient: LinearGradient(
        colors: [Color(0xFF0F3826), Color(0xFF1D5A3F), Color(0xFF13422E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      accentColor: Color(0xFFD4AF37),
    ),
    // 1: Obsidian Midnight
    CardVisualThemeData(
      name: 'Obsidian Midnight',
      gradient: LinearGradient(
        colors: [Color(0xFF18191D), Color(0xFF272930), Color(0xFF111215)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      accentColor: Color(0xFFE2E8F0),
    ),
    // 2: Royal Sapphire
    CardVisualThemeData(
      name: 'Royal Sapphire',
      gradient: LinearGradient(
        colors: [Color(0xFF0C2340), Color(0xFF1D4ED8), Color(0xFF172554)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      accentColor: Color(0xFF93C5FD),
    ),
    // 3: Ceylon Bronze Gold
    CardVisualThemeData(
      name: 'Bronze Gold',
      gradient: LinearGradient(
        colors: [Color(0xFF452207), Color(0xFF854D0E), Color(0xFF3F1D06)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      accentColor: Color(0xFFFDE047),
    ),
    // 4: Crimson Wine
    CardVisualThemeData(
      name: 'Crimson Wine',
      gradient: LinearGradient(
        colors: [Color(0xFF4C0519), Color(0xFF9F1239), Color(0xFF350613)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      accentColor: Color(0xFFFECDD3),
    ),
  ];
}

class CardVisualThemeData {
  final String name;
  final LinearGradient gradient;
  final Color textColor;
  final Color accentColor;

  const CardVisualThemeData({
    required this.name,
    required this.gradient,
    required this.textColor,
    required this.accentColor,
  });
}

class CardVisualWidget extends StatelessWidget {
  final String bankName;
  final String cardHolderName;
  final String cardNumber; // e.g. "•••• •••• •••• 4821" or raw digits
  final String expiry; // "MM/YY"
  final String cardBrand; // "visa", "mastercard", etc.
  final String cardType; // "Debit" or "Credit"
  final int themeIndex;
  final bool isDefault;
  final bool showFullNumber;
  final VoidCallback? onTap;

  const CardVisualWidget({
    super.key,
    required this.bankName,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiry,
    required this.cardBrand,
    this.cardType = 'Debit',
    this.themeIndex = 0,
    this.isDefault = false,
    this.showFullNumber = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = (themeIndex >= 0 && themeIndex < CardVisualThemes.themes.length)
        ? CardVisualThemes.themes[themeIndex]
        : CardVisualThemes.themes[0];

    // Format display card number
    String displayNumber = cardNumber;
    if (!showFullNumber && !cardNumber.contains('•') && cardNumber.replaceAll(' ', '').length >= 4) {
      final clean = cardNumber.replaceAll(' ', '');
      final last4 = clean.substring(clean.length - 4);
      displayNumber = '•••• •••• •••• $last4';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 205,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: theme.gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle background curves / watermarks for realism
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),

              // Foreground Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Bank Name + Card Type / Default Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bankName.toUpperCase(),
                                style: TextStyle(
                                  color: theme.textColor.withValues(alpha: 0.95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cardType.toUpperCase(),
                                style: TextStyle(
                                  color: theme.textColor.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.black87, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Chip & Contactless Row
                    Row(
                      children: [
                        _buildEmvChip(),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.contactless_rounded,
                          color: theme.textColor.withValues(alpha: 0.6),
                          size: 26,
                        ),
                      ],
                    ),

                    // Card Number
                    Text(
                      displayNumber.isEmpty ? '•••• •••• •••• ••••' : displayNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Courier',
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Row: Holder Name, Expiry, and Brand Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cardholder
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CARD HOLDER',
                                style: TextStyle(
                                  color: theme.textColor.withValues(alpha: 0.55),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cardHolderName.isEmpty
                                    ? 'YOUR NAME'
                                    : cardHolderName.toUpperCase(),
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Expiry
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPIRES',
                                style: TextStyle(
                                  color: theme.textColor.withValues(alpha: 0.55),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                expiry.isEmpty ? 'MM/YY' : expiry,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Brand Logo
                        _buildBrandLogo(cardBrand),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// EMV Metallic Smart Chip
  Widget _buildEmvChip() {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFE5C07B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFC79E4A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 32,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB58933), width: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 15,
            child: Container(height: 1, color: const Color(0xFFB58933)),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 14,
            child: Container(width: 1, color: const Color(0xFFB58933)),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 14,
            child: Container(width: 1, color: const Color(0xFFB58933)),
          ),
        ],
      ),
    );
  }

  /// Clean, high-fidelity card brand emblems
  Widget _buildBrandLogo(String brand) {
    final lower = brand.toLowerCase();
    if (lower == 'visa') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'VISA',
          style: TextStyle(
            color: Color(0xFF1A1F71),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      );
    } else if (lower == 'mastercard') {
      return SizedBox(
        width: 46,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB001B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (lower == 'amex') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF006FCF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'AMEX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
      );
    } else if (lower == 'discover') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6000),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'DISCOVER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'CARD',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
