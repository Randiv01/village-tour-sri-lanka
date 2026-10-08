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
                  (b.status == 'confirmed' || b.status == 'pending'))
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

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
