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
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfGuests;
  final double totalPrice;
  final String currency;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? notes;
  final String tourType; // 'Private Tour', 'Group Tour', etc.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GuideBooking({
    required this.id,
    required this.guideId,
    required this.packageId,
    required this.packageTitle,
    required this.guestId,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
    required this.startDate,
    required this.endDate,
    required this.numberOfGuests,
    required this.totalPrice,
    this.currency = 'LKR',
    required this.status,
    this.notes,
    this.tourType = 'Private Tour',
    this.createdAt,
    this.updatedAt,
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
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      numberOfGuests: (map['numberOfGuests'] as num?)?.toInt() ?? 1,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'LKR',
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      tourType: map['tourType'] ?? 'Private Tour',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
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
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'numberOfGuests': numberOfGuests,
      'totalPrice': totalPrice,
      'currency': currency,
      'status': status,
      'notes': notes,
      'tourType': tourType,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
