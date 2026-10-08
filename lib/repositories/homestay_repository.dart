import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homestay.dart';

class HomestayRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createHomestay(Homestay homestay) async {
    final docRef = await _firestore.collection('homestays').add(homestay.toMap());
    return docRef.id;
  }

  Future<void> updateHomestay(Homestay homestay) async {
    await _firestore.collection('homestays').doc(homestay.id).update(homestay.toMap());
  }

  Future<Homestay?> getHomestayById(String id) async {
    final doc = await _firestore.collection('homestays').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Homestay.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<List<Homestay>> getHostHomestays(String hostId) {
    return _firestore
        .collection('homestays')
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Homestay.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<Homestay>> getActiveHomestays() {
    return _firestore
        .collection('homestays')
        .where('status', isEqualTo: 'Active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Homestay.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
