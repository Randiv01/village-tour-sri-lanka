import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_inquiry.dart';

class ContactInquiryRepository {
  final FirebaseFirestore _firestore;

  ContactInquiryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _inquiriesCollection =>
      _firestore.collection('contact_inquiries');

  /// Stream of inquiries with optional status filtering
  Stream<List<ContactInquiry>> getInquiriesStream({String? status}) {
    Query<Map<String, dynamic>> query =
        _inquiriesCollection.orderBy('createdAt', descending: true);

    if (status != null && status != 'All' && status.isNotEmpty) {
      query = _inquiriesCollection
          .where('status', isEqualTo: status.toLowerCase())
          .orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactInquiry.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Submit a new inquiry from Contact Us form
  Future<String> submitInquiry(ContactInquiry inquiry) async {
    final docRef = await _inquiriesCollection.add(inquiry.toMap());
    return docRef.id;
  }

  /// Create or manually record an inquiry (Admin use)
  Future<String> createInquiryByAdmin(ContactInquiry inquiry) async {
    final docRef = await _inquiriesCollection.add(inquiry.toMap());
    return docRef.id;
  }

  /// Update full inquiry details
  Future<void> updateInquiry(ContactInquiry inquiry) async {
    final data = inquiry.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _inquiriesCollection.doc(inquiry.id).update(data);
  }

  /// Update status and optional admin internal notes
  Future<void> updateInquiryStatus(
    String id,
    String status, {
    String? adminNotes,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': status.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (adminNotes != null) {
      updateData['adminNotes'] = adminNotes;
    }

    await _inquiriesCollection.doc(id).update(updateData);
  }

  /// Delete an inquiry
  Future<void> deleteInquiry(String id) async {
    await _inquiriesCollection.doc(id).delete();
  }

  /// Stream count of pending inquiries for admin notifications/badges
  Stream<int> getPendingInquiriesCount() {
    return _inquiriesCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get single inquiry by id
  Future<ContactInquiry?> getInquiryById(String id) async {
    final doc = await _inquiriesCollection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ContactInquiry.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
