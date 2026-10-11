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
          final list = snapshot.docs
              .map((doc) => GalleryImage.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            if (a.isCover && !b.isCover) return -1;
            if (!a.isCover && b.isCover) return 1;
            return 0;
          });
          return list;
        });
  }

  Stream<List<GalleryImage>> getPublishedImagesStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => GalleryImage.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            if (a.isCover && !b.isCover) return -1;
            if (!a.isCover && b.isCover) return 1;
            return 0;
          });
          return list;
        });
  }

  Future<void> addImage(GalleryImage image) async {
    if (image.isCover) {
      await _unsetExistingCovers();
    }
    final docRef = _firestore.collection(_collection).doc();
    final data = image.toMap();
    await docRef.set(data);
  }

  Future<void> updateImage(GalleryImage image) async {
    if (image.isCover) {
      await _unsetExistingCovers(exceptId: image.id);
    }
    final data = image.toMap();
    await _firestore.collection(_collection).doc(image.id).update(data);
  }

  Future<void> setCoverImage(String id) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore.collection(_collection).get();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isCover': doc.id == id});
    }
    await batch.commit();
  }

  Future<void> _unsetExistingCovers({String? exceptId}) async {
    final existingCovers = await _firestore
        .collection(_collection)
        .where('isCover', isEqualTo: true)
        .get();
    final batch = _firestore.batch();
    for (var doc in existingCovers.docs) {
      if (doc.id != exceptId) {
        batch.update(doc.reference, {'isCover': false});
      }
    }
    await batch.commit();
  }

  Future<void> deleteImage(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
