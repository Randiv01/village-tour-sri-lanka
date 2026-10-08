import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guide_booking.dart';

class GuideBookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'guide_bookings';

  // Stream of all bookings for a guide
  Stream<List<GuideBooking>> getGuideBookingsStream(String guideId) {
    return _firestore
        .collection(_collection)
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => GuideBooking.fromMap(doc.data(), doc.id))
              .toList();
          bookings.sort((a, b) => a.startDate.compareTo(b.startDate));
          return bookings;
        });
  }

  // Stream of upcoming bookings for a guide
  Stream<List<GuideBooking>> getUpcomingBookingsStream(String guideId) {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => GuideBooking.fromMap(doc.data(), doc.id))
              .where((b) =>
                  b.startDate.isAfter(now) &&
                  (b.status == 'confirmed' || b.status == 'accepted'))
              .toList();
          bookings.sort((a, b) => a.startDate.compareTo(b.startDate));
          return bookings;
        });
  }

  // Get a single booking
  Future<GuideBooking?> getBooking(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return GuideBooking.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> _createNotification(String guideId, String title, String body, String type, String bookingId) async {
    await _firestore.collection('notifications').add({
      'userId': guideId,
      'title': title,
      'body': body,
      'type': type,
      'bookingId': bookingId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a new booking
  Future<String> createBooking(GuideBooking booking) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = {
      ...booking.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    
    await _createNotification(
      booking.guideId,
      'New Booking Request',
      '${booking.guestName} has requested to book ${booking.packageTitle}.',
      'booking_new',
      docRef.id,
    );

    return docRef.id;
  }

  // Check if dates overlap with existing confirmed/pending/accepted bookings
  Future<bool> checkDateOverlap(String packageId, DateTime startDate, DateTime endDate) async {
    // Note: Firestore doesn't easily support range queries on multiple fields.
    // So we fetch relevant active bookings and check locally.
    final snapshot = await _firestore
        .collection(_collection)
        .where('packageId', isEqualTo: packageId)
        .where('status', whereIn: ['pending', 'accepted', 'confirmed'])
        .get();

    for (var doc in snapshot.docs) {
      final b = GuideBooking.fromMap(doc.data(), doc.id);
      
      // Start dates are inclusive, end dates are inclusive.
      // Logic: If (newStart <= existingEnd) AND (newEnd >= existingStart) -> OVERLAP
      // Since it's dates without time (or midnight), we use <= and >= for inclusive overlap.
      final existingStart = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
      final existingEnd = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
      final newStart = DateTime(startDate.year, startDate.month, startDate.day);
      final newEnd = DateTime(endDate.year, endDate.month, endDate.day);

      if (newStart.compareTo(existingEnd) <= 0 && newEnd.compareTo(existingStart) >= 0) {
        return true; // Overlap found
      }
    }
    return false;
  }

  // Update booking status
  Future<void> updateBookingStatus(
    String bookingId, 
    String status, {
    String? paymentStatus,
    String? rejectionReason,
    String? transactionId,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    DateTime? paidAt,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (paymentStatus != null) updates['paymentStatus'] = paymentStatus;
    if (rejectionReason != null) updates['rejectionReason'] = rejectionReason;
    if (transactionId != null) updates['transactionId'] = transactionId;
    if (acceptedAt != null) updates['acceptedAt'] = Timestamp.fromDate(acceptedAt);
    if (rejectedAt != null) updates['rejectedAt'] = Timestamp.fromDate(rejectedAt);
    if (paidAt != null) updates['paidAt'] = Timestamp.fromDate(paidAt);

    await _firestore.collection(_collection).doc(bookingId).update(updates);

    // Fetch booking to get details for notification
    final booking = await getBooking(bookingId);
    if (booking != null) {
      if (paymentStatus == 'paid') {
        await _createNotification(
          booking.guideId,
          'Payment Successful',
          'Payment received for ${booking.packageTitle} from ${booking.guestName}.',
          'payment_success',
          bookingId,
        );
      } else if (paymentStatus == 'failed') {
         await _createNotification(
          booking.guideId,
          'Payment Failed',
          'Payment failed for ${booking.packageTitle} from ${booking.guestName}.',
          'payment_failed',
          bookingId,
        );
      } else if (status == 'cancelled') {
         await _createNotification(
          booking.guideId,
          'Booking Cancelled',
          '${booking.guestName} has cancelled the booking for ${booking.packageTitle}.',
          'booking_cancelled',
          bookingId,
        );
      }
    }
  }

  // Count upcoming bookings
  Future<int> countUpcomingBookings(String guideId) async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_collection)
        .where('guideId', isEqualTo: guideId)
        .get();
    return snapshot.docs
        .map((doc) => GuideBooking.fromMap(doc.data(), doc.id))
        .where((b) =>
            b.startDate.isAfter(now) &&
            (b.status == 'confirmed' || b.status == 'pending'))
        .length;
  }
}
