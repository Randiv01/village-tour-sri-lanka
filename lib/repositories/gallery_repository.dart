import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gallery_image.dart';

class GalleryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'gallery';

  Stream<List<GalleryImage>> getAllImagesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GalleryImage.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<List<GalleryImage>> getPublishedImagesStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GalleryImage.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> addImage(GalleryImage image) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = image.toMap();
    await docRef.set(data);
  }

  Future<void> updateImage(GalleryImage image) async {
    final data = image.toMap();
    await _firestore.collection(_collection).doc(image.id).update(data);
  }

  Future<void> deleteImage(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
