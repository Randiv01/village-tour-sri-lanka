import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'payments';

  Future<String> createPayment(PaymentModel payment) async {
    final docRef = _firestore.collection(_collection).doc();
    await docRef.set({
      ...payment.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updatePaymentStatus(
    String paymentId,
    String status, {
    String? transactionId,
    DateTime? paidAt,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (transactionId != null) updates['transactionId'] = transactionId;
    if (paidAt != null) updates['paidAt'] = Timestamp.fromDate(paidAt);

    await _firestore.collection(_collection).doc(paymentId).update(updates);
  }

  Future<PaymentModel?> getPayment(String paymentId) async {
    final doc = await _firestore.collection(_collection).doc(paymentId).get();
    if (doc.exists && doc.data() != null) {
      return PaymentModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
