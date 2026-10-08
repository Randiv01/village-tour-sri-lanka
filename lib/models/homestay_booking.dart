import 'package:cloud_firestore/cloud_firestore.dart';

class HomestayBooking {
  final String id;
  final String bookingType; // 'homestay'
  final String homestayId;
  final String homestayTitle;
  final String hostId;
  final String travelerId;
  final String travelerName;
  final String travelerEmail;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfNights;
  final int guestCount;
  final double pricePerNight;
  final double accommodationAmount;
  final double addOnAmount;
  final double totalAmount;
  final String currency;
  final String bookingStatus; // 'pending', 'accepted', 'rejected', 'confirmed', 'cancelled'
  final String paymentStatus; // 'unpaid', 'failed', 'paid', 'refunded'
  final String? rejectionReason;
  final List<Map<String, dynamic>> selectedAddOns; // { title, price, quantity }
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? paidAt;
  final String? transactionId;

  HomestayBooking({
    required this.id,
    this.bookingType = 'homestay',
    required this.homestayId,
    required this.homestayTitle,
    required this.hostId,
    required this.travelerId,
    required this.travelerName,
    required this.travelerEmail,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfNights,
    required this.guestCount,
    required this.pricePerNight,
    required this.accommodationAmount,
    required this.addOnAmount,
    required this.totalAmount,
    this.currency = 'LKR',
    this.bookingStatus = 'pending',
    this.paymentStatus = 'unpaid',
    this.rejectionReason,
    this.selectedAddOns = const [],
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.paidAt,
    this.transactionId,
  });

  factory HomestayBooking.fromMap(Map<String, dynamic> map, String documentId) {
    return HomestayBooking(
      id: documentId,
      bookingType: map['bookingType'] ?? 'homestay',
      homestayId: map['homestayId'] ?? '',
      homestayTitle: map['homestayTitle'] ?? '',
      hostId: map['hostId'] ?? '',
      travelerId: map['travelerId'] ?? '',
      travelerName: map['travelerName'] ?? '',
      travelerEmail: map['travelerEmail'] ?? '',
      checkInDate: (map['checkInDate'] as Timestamp).toDate(),
      checkOutDate: (map['checkOutDate'] as Timestamp).toDate(),
      numberOfNights: (map['numberOfNights'] as num?)?.toInt() ?? 1,
      guestCount: (map['guestCount'] as num?)?.toInt() ?? 1,
      pricePerNight: (map['pricePerNight'] as num?)?.toDouble() ?? 0.0,
      accommodationAmount: (map['accommodationAmount'] as num?)?.toDouble() ?? 0.0,
      addOnAmount: (map['addOnAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'LKR',
      bookingStatus: map['bookingStatus'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      rejectionReason: map['rejectionReason'],
      selectedAddOns: List<Map<String, dynamic>>.from(map['selectedAddOns'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (map['rejectedAt'] as Timestamp?)?.toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingType': bookingType,
      'homestayId': homestayId,
      'homestayTitle': homestayTitle,
      'hostId': hostId,
      'travelerId': travelerId,
      'travelerName': travelerName,
      'travelerEmail': travelerEmail,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'numberOfNights': numberOfNights,
      'guestCount': guestCount,
      'pricePerNight': pricePerNight,
      'accommodationAmount': accommodationAmount,
      'addOnAmount': addOnAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'bookingStatus': bookingStatus,
      'paymentStatus': paymentStatus,
      'rejectionReason': rejectionReason,
      'selectedAddOns': selectedAddOns,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      if (transactionId != null) 'transactionId': transactionId,
    };
  }
}
