import 'package:cloud_firestore/cloud_firestore.dart';

class GuideBooking {
  final String id;
  final String guideId;
  final String packageId;
  final String packageTitle;
  final String guestId;
  final String guestName;
  final String guestEmail;
  final String? guestPhone;
  final String? guestProfileUrl;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfGuests;
  final double totalPrice;
  final String currency;
  final String
  status; // 'pending', 'confirmed', 'cancelled', 'completed', 'rejected'
  final String
  paymentStatus; // 'pending', 'paid', 'failed', 'refunded', 'unpaid'
  final String? rejectionReason;
  final String? transactionId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? paidAt;

  GuideBooking({
    required this.id,
    required this.guideId,
    required this.packageId,
    required this.packageTitle,
    required this.guestId,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
    this.guestProfileUrl,
    required this.startDate,
    required this.endDate,
    required this.numberOfGuests,
    required this.totalPrice,
    this.currency = 'LKR',
    required this.status,
    required this.paymentStatus,
    this.rejectionReason,
    this.transactionId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.paidAt,
  });

  factory GuideBooking.fromMap(Map<String, dynamic> map, String documentId) {
    return GuideBooking(
      id: documentId,
      guideId: map['guideId'] ?? '',
      packageId: map['packageId'] ?? '',
      packageTitle: map['packageTitle'] ?? '',
      guestId: map['guestId'] ?? '',
      guestName: map['guestName'] ?? '',
      guestEmail: map['guestEmail'] ?? '',
      guestPhone: map['guestPhone'],
      guestProfileUrl: map['guestProfileUrl'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      numberOfGuests: (map['numberOfGuests'] as num?)?.toInt() ?? 1,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'LKR',
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      rejectionReason: map['rejectionReason'],
      transactionId: map['transactionId'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (map['rejectedAt'] as Timestamp?)?.toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guideId': guideId,
      'packageId': packageId,
      'packageTitle': packageTitle,
      'guestId': guestId,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'guestPhone': guestPhone,
      'guestProfileUrl': guestProfileUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'numberOfGuests': numberOfGuests,
      'totalPrice': totalPrice,
      'currency': currency,
      'status': status,
      'paymentStatus': paymentStatus,
      'rejectionReason': rejectionReason,
      'transactionId': transactionId,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    };
  }
}
