import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentCardModel {
  final String id;
  final String userId;
  final String cardHolderName;
  final String cardNumberMasked; // e.g. "•••• •••• •••• 4821"
  final String last4; // e.g. "4821"
  final String cardBrand; // "visa", "mastercard", "amex", "discover", "other"
  final String cardType; // "Debit", "Credit"
  final String bankName; // e.g. "Commercial Bank", "Sampath Bank", "HNB"
  final String expiryMonth; // "08"
  final String expiryYear; // "27"
  final int colorThemeIndex; // 0 to 4
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentCardModel({
    required this.id,
    required this.userId,
    required this.cardHolderName,
    required this.cardNumberMasked,
    required this.last4,
    required this.cardBrand,
    this.cardType = 'Debit',
    this.bankName = 'Commercial Bank',
    required this.expiryMonth,
    required this.expiryYear,
    this.colorThemeIndex = 0,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  String get formattedExpiry => '$expiryMonth/$expiryYear';

  bool get isExpired {
    final month = int.tryParse(expiryMonth);
    final year = int.tryParse(expiryYear);
    if (month == null || year == null) return true;

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear) return true;
    if (year == currentYear && month < currentMonth) return true;
    return false;
  }

  factory PaymentCardModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return PaymentCardModel(
      id: documentId,
      userId: map['userId'] ?? '',
      cardHolderName: map['cardHolderName'] ?? '',
      cardNumberMasked: map['cardNumberMasked'] ?? '•••• •••• •••• ••••',
      last4: map['last4'] ?? '',
      cardBrand: map['cardBrand'] ?? 'visa',
      cardType: map['cardType'] ?? 'Debit',
      bankName: map['bankName'] ?? 'Commercial Bank',
      expiryMonth: map['expiryMonth'] ?? '',
      expiryYear: map['expiryYear'] ?? '',
      colorThemeIndex: (map['colorThemeIndex'] as num?)?.toInt() ?? 0,
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'cardHolderName': cardHolderName,
      'cardNumberMasked': cardNumberMasked,
      'last4': last4,
      'cardBrand': cardBrand,
      'cardType': cardType,
      'bankName': bankName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'colorThemeIndex': colorThemeIndex,
      'isDefault': isDefault,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  PaymentCardModel copyWith({
    String? id,
    String? userId,
    String? cardHolderName,
    String? cardNumberMasked,
    String? last4,
    String? cardBrand,
    String? cardType,
    String? bankName,
    String? expiryMonth,
    String? expiryYear,
    int? colorThemeIndex,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNumberMasked: cardNumberMasked ?? this.cardNumberMasked,
      last4: last4 ?? this.last4,
      cardBrand: cardBrand ?? this.cardBrand,
      cardType: cardType ?? this.cardType,
      bankName: bankName ?? this.bankName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      colorThemeIndex: colorThemeIndex ?? this.colorThemeIndex,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
