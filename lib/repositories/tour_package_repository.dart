import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tour_package.dart';

class TourPackageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tour_packages';

  // Stream of all packages for the current guide
  Stream<List<TourPackage>> getGuidePackagesStream(String guideId) {
    return _firestore
        .collection(_collection)
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map((snapshot) {
          final packages = snapshot.docs
              .map((doc) => TourPackage.fromMap(doc.data(), doc.id))
              .toList();
          packages.sort((a, b) {
            final aTime = a.createdAt ?? DateTime(2000);
            final bTime = b.createdAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return packages;
        });
  }

  // Stream of active packages for the current guide
  Stream<List<TourPackage>> getGuideActivePackagesStream(String guideId) {
    return _firestore
        .collection(_collection)
        .where('guideId', isEqualTo: guideId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TourPackage.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Stream of all active packages (for travelers)
  Stream<List<TourPackage>> getActivePackagesStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final packages = snapshot.docs
              .map((doc) => TourPackage.fromMap(doc.data(), doc.id))
              .toList();
          packages.sort((a, b) {
            final aTime = a.createdAt ?? DateTime(2000);
            final bTime = b.createdAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return packages;
        });
  }

  // Get a single package
  Future<TourPackage?> getPackage(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return TourPackage.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Create a new package
  Future<String> createPackage(TourPackage package) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = {
      ...package.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    return docRef.id;
  }

  // Update a package (only if owned by guideId)
  Future<void> updatePackage(TourPackage package) async {
    await _firestore
        .collection(_collection)
        .doc(package.id)
        .update(package.toMap());
  }

  // Update package status
  Future<void> updatePackageStatus(String packageId, String status) async {
    await _firestore.collection(_collection).doc(packageId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a package
  Future<void> deletePackage(String packageId) async {
    await _firestore.collection(_collection).doc(packageId).delete();
  }

  // Check if package has any bookings
  Future<bool> hasBookings(String packageId, String guideId) async {
    final snapshot = await _firestore
        .collection('guide_bookings')
        .where('packageId', isEqualTo: packageId)
        .where('guideId', isEqualTo: guideId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
