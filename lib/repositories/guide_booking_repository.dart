import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/guide_booking.dart';
import 'notification_repository.dart';

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
              .where(
                (b) =>
                    b.startDate.isAfter(now) &&
                    (b.status == 'confirmed' || b.status == 'accepted'),
              )
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

  Future<void> _createNotification(
    String guideId,
    String title,
    String body,
    String type,
    String bookingId, {
    String? packageTitle,
  }) async {
    try {
      await NotificationRepository().sendNotification(
        userId: guideId,
        recipientRole: 'guide',
        title: title,
        message: body,
        type: type,
        relatedId: bookingId,
        packageTitle: packageTitle,
        metadata: {
          'isGuideBooking': true,
          'bookingId': bookingId,
          'packageTitle': ?packageTitle,
        },
      );
    } catch (_) {}
  }

  // Create a new booking
  Future<String> createBooking(GuideBooking booking) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = {
      ...booking.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);

    try {
      await NotificationRepository().sendNotification(
        userId: booking.guideId,
        recipientRole: 'guide',
        title: 'New Booking Request',
        message: '${booking.guestName} has requested to book ${booking.packageTitle}.',
        type: 'booking_new',
        relatedId: docRef.id,
        packageTitle: booking.packageTitle,
        metadata: {
          'isGuideBooking': true,
          'bookingId': docRef.id,
          'guestId': booking.guestId,
          'guestName': booking.guestName,
          'packageId': booking.packageId,
          'packageTitle': booking.packageTitle,
        },
      );
    } catch (_) {}

    return docRef.id;
  }

  // Check if dates overlap with existing confirmed/pending/accepted bookings
  Future<bool> checkDateOverlap(
    String packageId,
    DateTime startDate,
    DateTime endDate,
  ) async {
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
      final existingStart = DateTime(
        b.startDate.year,
        b.startDate.month,
        b.startDate.day,
      );
      final existingEnd = DateTime(
        b.endDate.year,
        b.endDate.month,
        b.endDate.day,
      );
      final newStart = DateTime(startDate.year, startDate.month, startDate.day);
      final newEnd = DateTime(endDate.year, endDate.month, endDate.day);

      if (newStart.compareTo(existingEnd) <= 0 &&
          newEnd.compareTo(existingStart) >= 0) {
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
    if (acceptedAt != null) {
      updates['acceptedAt'] = Timestamp.fromDate(acceptedAt);
    }
    if (rejectedAt != null) {
      updates['rejectedAt'] = Timestamp.fromDate(rejectedAt);
    }
    if (paidAt != null) updates['paidAt'] = Timestamp.fromDate(paidAt);

    await _firestore.collection(_collection).doc(bookingId).update(updates);

    // Fetch booking to get details for notification
    final booking = await getBooking(bookingId);
    if (booking != null) {
      // Mark any pending booking notifications for the guide for this booking as read
      try {
        final guideNotifs = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: booking.guideId)
            .where('read', isEqualTo: false)
            .get();
        for (var doc in guideNotifs.docs) {
          final data = doc.data();
          final relId = data['relatedId'] ?? data['bookingId'];
          if (relId == bookingId) {
            doc.reference.update({'read': true});
          }
        }
      } catch (_) {}

      // Resolve guide name
      String guideName = 'Tour Guide';
      try {
        final guideDoc =
            await _firestore.collection('users').doc(booking.guideId).get();
        if (guideDoc.exists && guideDoc.data() != null) {
          guideName = guideDoc.data()!['fullName'] ??
              guideDoc.data()!['name'] ??
              'Tour Guide';
        }
      } catch (_) {}

      if (status == 'accepted' || status == 'confirmed') {
        // 🔔 Notify traveler that their booking is approved!
        try {
          await NotificationRepository().sendNotification(
            userId: booking.guestId,
            recipientRole: 'traveler',
            type: 'booking_accepted',
            title: 'Booking Approved',
            message:
                'Your booking request for "${booking.packageTitle}" was approved by guide $guideName.',
            relatedId: bookingId,
            guideName: guideName,
            packageTitle: booking.packageTitle,
            metadata: {
              'isGuideBooking': true,
              'bookingId': bookingId,
              'guideId': booking.guideId,
              'guideName': guideName,
              'packageId': booking.packageId,
              'packageTitle': booking.packageTitle,
              'status': status,
            },
          );
        } catch (_) {}
      } else if (status == 'rejected') {
        // 🔔 Notify traveler that their booking was declined!
        final reasonSuffix = (rejectionReason != null && rejectionReason.isNotEmpty)
            ? ' Reason: $rejectionReason'
            : '';
        try {
          await NotificationRepository().sendNotification(
            userId: booking.guestId,
            recipientRole: 'traveler',
            type: 'booking_rejected',
            title: 'Booking Rejected',
            message:
                'Your booking request for "${booking.packageTitle}" was rejected by guide $guideName.$reasonSuffix',
            relatedId: bookingId,
            guideName: guideName,
            packageTitle: booking.packageTitle,
            metadata: {
              'isGuideBooking': true,
              'bookingId': bookingId,
              'guideId': booking.guideId,
              'guideName': guideName,
              'packageId': booking.packageId,
              'packageTitle': booking.packageTitle,
              'status': status,
              'rejectionReason': rejectionReason,
            },
          );
        } catch (_) {}
      }

      if (paymentStatus == 'paid') {
        await _createNotification(
          booking.guideId,
          'Payment Successful',
          'Payment received for ${booking.packageTitle} from ${booking.guestName}.',
          'payment_success',
          bookingId,
          packageTitle: booking.packageTitle,
        );
      } else if (paymentStatus == 'failed') {
        await _createNotification(
          booking.guideId,
          'Payment Failed',
          'Payment failed for ${booking.packageTitle} from ${booking.guestName}.',
          'payment_failed',
          bookingId,
          packageTitle: booking.packageTitle,
        );
      } else if (status == 'cancelled') {
        await _createNotification(
          booking.guideId,
          'Booking Cancelled',
          '${booking.guestName} has cancelled the booking for ${booking.packageTitle}.',
          'booking_cancelled',
          bookingId,
          packageTitle: booking.packageTitle,
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
        .where(
          (b) =>
              b.startDate.isAfter(now) &&
              (b.status == 'confirmed' || b.status == 'pending'),
        )
        .length;
  }
}
