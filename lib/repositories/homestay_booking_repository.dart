import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/homestay_booking.dart';

class HomestayBookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new booking
  Future<String> createBooking(HomestayBooking booking) async {
    final docRef = await _firestore
        .collection('homestay_bookings')
        .add(booking.toMap());

    // Create a notification for the host
    await _firestore.collection('notifications').add({
      'userId': booking.hostId,
      'title': 'New Booking Request',
      'message':
          '${booking.travelerName} requested a booking for ${booking.homestayTitle}.',
      'type': 'booking',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedId': docRef.id,
    });

    return docRef.id;
  }

  // Get a booking by ID
  Future<HomestayBooking?> getBookingById(String id) async {
    final doc = await _firestore.collection('homestay_bookings').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return HomestayBooking.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Get all bookings for a traveler
  Stream<List<HomestayBooking>> getTravelerBookings(String travelerId) {
    return _firestore
        .collection('homestay_bookings')
        .where('travelerId', isEqualTo: travelerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HomestayBooking.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get all bookings for a host
  Stream<List<HomestayBooking>> getHostBookings(String hostId) {
    return _firestore
        .collection('homestay_bookings')
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HomestayBooking.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get confirmed/pending/accepted bookings for a homestay to check availability
  Future<List<HomestayBooking>> getActiveBookingsForHomestay(
    String homestayId,
  ) async {
    final snapshot = await _firestore
        .collection('homestay_bookings')
        .where('homestayId', isEqualTo: homestayId)
        .where('bookingStatus', whereIn: ['pending', 'accepted', 'confirmed'])
        .get();

    return snapshot.docs
        .map((doc) => HomestayBooking.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Update booking status
  Future<void> updateBookingStatus(
    String id,
    String status, {
    String? paymentStatus,
    String? rejectionReason,
    String? transactionId,
    DateTime? paidAt,
  }) async {
    final Map<String, dynamic> updates = {
      'bookingStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (paymentStatus != null) updates['paymentStatus'] = paymentStatus;
    if (rejectionReason != null) updates['rejectionReason'] = rejectionReason;
    if (transactionId != null) updates['transactionId'] = transactionId;
    if (paidAt != null) updates['paidAt'] = Timestamp.fromDate(paidAt);

    if (status == 'accepted') {
      updates['acceptedAt'] = FieldValue.serverTimestamp();
    }
    if (status == 'rejected') {
      updates['rejectedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('homestay_bookings').doc(id).update(updates);

    // Notify traveler
    final booking = await getBookingById(id);
    if (booking != null) {
      String msg = '';
      if (status == 'accepted') {
        msg =
            'Your booking request for ${booking.homestayTitle} was accepted! Payment required.';
      }
      if (status == 'rejected') {
        msg = 'Your booking request for ${booking.homestayTitle} was rejected.';
      }
      if (status == 'confirmed') {
        msg = 'Your payment was successful and booking is confirmed.';
      }

      if (msg.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': booking.travelerId,
          'title': 'Booking Status Updated',
          'message': msg,
          'type': 'booking',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'relatedId': id,
        });
      }
    }
  }
}
