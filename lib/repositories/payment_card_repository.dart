import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_card.dart';

class PaymentCardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userCardsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('saved_cards');
  }

  /// Stream list of saved cards for a user (ordered by isDefault desc, createdAt desc)
  Stream<List<PaymentCardModel>> streamCards(String userId) {
    return _userCardsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentCardModel.fromMap(doc.data(), doc.id))
          .toList();
      // Put default card first
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return 0;
      });
      return list;
    });
  }

  /// Get list of saved cards for a user
  Future<List<PaymentCardModel>> getCards(String userId) async {
    final snapshot = await _userCardsRef(userId)
        .orderBy('createdAt', descending: true)
        .get();
    final list = snapshot.docs
        .map((doc) => PaymentCardModel.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });
    return list;
  }

  /// Get default card
  Future<PaymentCardModel?> getDefaultCard(String userId) async {
    final snapshot = await _userCardsRef(userId)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return PaymentCardModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    }

    // If no explicit default, get the most recent card if any
    final anyCards = await _userCardsRef(userId).limit(1).get();
    if (anyCards.docs.isNotEmpty) {
      return PaymentCardModel.fromMap(
        anyCards.docs.first.data(),
        anyCards.docs.first.id,
      );
    }

    return null;
  }

  /// Add a new card
  Future<String> addCard(PaymentCardModel card) async {
    final cardsRef = _userCardsRef(card.userId);
    final existingSnapshot = await cardsRef.limit(1).get();

    // If this is the user's first card, force it to be default
    bool shouldBeDefault = card.isDefault || existingSnapshot.docs.isEmpty;

    if (shouldBeDefault) {
      // Unset default on existing cards
      final allCards = await cardsRef.where('isDefault', isEqualTo: true).get();
      final batch = _firestore.batch();
      for (var doc in allCards.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    }

    final newDoc = cardsRef.doc();
    final finalCard = card.copyWith(
      id: newDoc.id,
      isDefault: shouldBeDefault,
    );

    await newDoc.set({
      ...finalCard.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newDoc.id;
  }

  /// Update existing card details (cardHolderName, bankName, cardType, expiry, theme, isDefault)
  Future<void> updateCard(PaymentCardModel card) async {
    final cardsRef = _userCardsRef(card.userId);

    if (card.isDefault) {
      // Unset default on other cards
      final allCards = await cardsRef.where('isDefault', isEqualTo: true).get();
      final batch = _firestore.batch();
      for (var doc in allCards.docs) {
        if (doc.id != card.id) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
      await batch.commit();
    }

    await cardsRef.doc(card.id).update({
      'cardHolderName': card.cardHolderName,
      'bankName': card.bankName,
      'cardType': card.cardType,
      'expiryMonth': card.expiryMonth,
      'expiryYear': card.expiryYear,
      'colorThemeIndex': card.colorThemeIndex,
      'isDefault': card.isDefault,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Set a card as default
  Future<void> setDefaultCard(String userId, String cardId) async {
    final cardsRef = _userCardsRef(userId);
    final allCards = await cardsRef.get();

    final batch = _firestore.batch();
    for (var doc in allCards.docs) {
      batch.update(doc.reference, {
        'isDefault': doc.id == cardId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Delete a card
  Future<void> deleteCard(String userId, String cardId) async {
    final cardsRef = _userCardsRef(userId);
    final targetDoc = await cardsRef.doc(cardId).get();
    final wasDefault = targetDoc.data()?['isDefault'] == true;

    await cardsRef.doc(cardId).delete();

    // If the deleted card was default, set another card as default if available
    if (wasDefault) {
      final remaining = await cardsRef.limit(1).get();
      if (remaining.docs.isNotEmpty) {
        await remaining.docs.first.reference.update({
          'isDefault': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
