import 'package:flutter/services.dart';

enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  jcb,
  unionpay,
  unknown,
}

class CardValidator {
  static const List<String> popularSriLankanBanks = [
    'Commercial Bank of Ceylon',
    'Sampath Bank',
    'Hatton National Bank (HNB)',
    'Bank of Ceylon (BOC)',
    'People\'s Bank',
    'Nations Trust Bank (NTB)',
    'Seylan Bank',
    'HSBC Sri Lanka',
    'Standard Chartered Sri Lanka',
    'DFCC Bank',
    'National Development Bank (NDB)',
    'Pan Asia Bank',
    'Other / International Bank',
  ];

  /// Detect brand based on first digits (BIN / IIN)
  static CardBrand detectBrand(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return CardBrand.unknown;

    if (clean.startsWith('4')) {
      return CardBrand.visa;
    }

    // Mastercard: 51-55 or 2221-2720
    if (clean.length >= 2) {
      final prefix2 = int.tryParse(clean.substring(0, 2)) ?? 0;
      if (prefix2 >= 51 && prefix2 <= 55) {
        return CardBrand.mastercard;
      }
      if (clean.length >= 4) {
        final prefix4 = int.tryParse(clean.substring(0, 4)) ?? 0;
        if (prefix4 >= 2221 && prefix4 <= 2720) {
          return CardBrand.mastercard;
        }
      }
    }

    // Amex: 34 or 37
    if (clean.startsWith('34') || clean.startsWith('37')) {
      return CardBrand.amex;
    }

    // Discover: 6011, 622126-622925, 644-649, 65
    if (clean.startsWith('6011') || clean.startsWith('65')) {
      return CardBrand.discover;
    }

    // JCB: 3528-3589
    if (clean.length >= 4) {
      final prefix4 = int.tryParse(clean.substring(0, 4)) ?? 0;
      if (prefix4 >= 3528 && prefix4 <= 3589) {
        return CardBrand.jcb;
      }
    }

    // UnionPay: 62
    if (clean.startsWith('62')) {
      return CardBrand.unionpay;
    }

    return CardBrand.unknown;
  }

  static String brandToString(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return 'visa';
      case CardBrand.mastercard:
        return 'mastercard';
      case CardBrand.amex:
        return 'amex';
      case CardBrand.discover:
        return 'discover';
      case CardBrand.jcb:
        return 'jcb';
      case CardBrand.unionpay:
        return 'unionpay';
      case CardBrand.unknown:
        return 'other';
    }
  }

  static String brandDisplayName(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'American Express';
      case 'discover':
        return 'Discover';
      case 'jcb':
        return 'JCB';
      case 'unionpay':
        return 'UnionPay';
      default:
        return 'Card';
    }
  }

  /// Validate card number using Luhn algorithm (Mod 10)
  static bool validateCardNumber(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 13 || clean.length > 19) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = clean.length - 1; i >= 0; i--) {
      int digit = int.parse(clean[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Validate Expiry Date MM/YY
  static String? validateExpiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }

    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Use MM/YY format';
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || month < 1 || month > 12) {
      return 'Invalid month (01-12)';
    }

    if (year == null || parts[1].length != 2) {
      return 'Invalid year (YY)';
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }

    if (year > currentYear + 25) {
      return 'Year is too far in future';
    }

    return null;
  }

  /// Validate CVV
  static String? validateCVV(String? value, {CardBrand brand = CardBrand.unknown}) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }

    final clean = value.replaceAll(RegExp(r'\D'), '');
    final requiredLength = brand == CardBrand.amex ? 4 : 3;

    if (clean.length != requiredLength) {
      return brand == CardBrand.amex ? 'Amex requires 4-digit CVV' : '3-digit CVV required';
    }

    return null;
  }

  /// Validate Cardholder Name
  static String? validateHolderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cardholder name is required';
    }

    if (value.trim().length < 3) {
      return 'Please enter full name (at least 3 characters)';
    }

    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(value)) {
      return 'Name contains invalid characters';
    }

    return null;
  }

  /// Mask full card number: e.g. "4242 4242 4242 4242" -> "•••• •••• •••• 4242"
  static String maskCardNumber(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 4) return '•••• •••• •••• ••••';
    final last4 = clean.substring(clean.length - 4);
    if (clean.length == 15) {
      // Amex format (4-6-5)
      return '•••• •••••• •$last4';
    }
    return '•••• •••• •••• $last4';
  }

  /// Extract last 4 digits
  static String getLast4(String cardNumber) {
    final clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 4) return clean;
    return clean.substring(clean.length - 4);
  }
}

/// Formatter that automatically inserts spaces into card numbers
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (clean.length > 19) return oldValue;

    final isAmex = clean.startsWith('34') || clean.startsWith('37');
    final buffer = StringBuffer();

    if (isAmex) {
      // Amex format: 4 - 6 - 5
      for (int i = 0; i < clean.length; i++) {
        buffer.write(clean[i]);
        if ((i == 3 || i == 9) && i != clean.length - 1) {
          buffer.write(' ');
        }
      }
    } else {
      // Standard: 4 - 4 - 4 - 4
      for (int i = 0; i < clean.length; i++) {
        buffer.write(clean[i]);
        if ((i + 1) % 4 == 0 && i != clean.length - 1) {
          buffer.write(' ');
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter for Expiry Date MM/YY
class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 4) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
