import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String bookingId;
  final String bookingType; // 'tour_package', 'homestay', etc.
  final String userId;
  final double amount;
  final String currency;
  final String status; // 'unpaid', 'paid', 'failed'
  final String? transactionId;
  final String description;
  final DateTime? createdAt;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.bookingType,
    required this.userId,
    required this.amount,
    this.currency = 'LKR',
    required this.status,
    this.transactionId,
    required this.description,
    this.createdAt,
    this.paidAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PaymentModel(
      id: documentId,
      bookingId: map['bookingId'] ?? '',
      bookingType: map['bookingType'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'LKR',
      status: map['status'] ?? 'unpaid',
      transactionId: map['transactionId'],
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'bookingType': bookingType,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'transactionId': transactionId,
      'description': description,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    };
  }
}
