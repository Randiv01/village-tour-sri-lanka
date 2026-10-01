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

  Future<Destination?> getDestination(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Destination.fromMap(doc.data()!, doc.id);
    }
    return null;
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
