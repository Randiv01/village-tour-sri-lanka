import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/destination.dart';

class DestinationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'destinations';

  Stream<List<Destination>> getDestinationsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Destination.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<Destination>> getActiveDestinationsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Destination.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          return list;
        });
  }

  Stream<List<Destination>> getPopularActiveDestinationsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Destination.fromMap(doc.data(), doc.id))
              .where((dest) => dest.isPopular)
              .toList();
          list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          return list;
        });
  }

  Future<Destination?> getDestination(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Destination.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<bool> checkNameExists(String name, {String? excludeId}) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final nameLower = name.trim().toLowerCase();

      for (var doc in snapshot.docs) {
        if (excludeId != null && doc.id == excludeId) continue;

        final docName =
            (doc.data()['name'] as String?)?.trim().toLowerCase() ?? '';
        if (docName == nameLower) {
          return true;
        }
      }
      return false;
    } catch (e) {
      // If error occurs, assume it doesn't exist so we don't block saving completely
      // or we could throw. But better to just log and return false.
      return false;
    }
  }

  Future<void> createDestination(Destination destination) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = destination.toMap();
    await docRef.set(data);
  }

  Future<void> updateDestination(Destination destination) async {
    final data = destination.toMap();
    await _firestore.collection(_collection).doc(destination.id).update(data);
  }

  Future<void> deactivateDestination(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reactivateDestination(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDestination(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
