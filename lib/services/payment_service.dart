import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/payment.dart';
import '../models/payment_card.dart';
import '../repositories/payment_repository.dart';
import '../repositories/payment_card_repository.dart';
import '../repositories/guide_booking_repository.dart';
import '../repositories/homestay_booking_repository.dart';
import '../services/email_service.dart';
import '../utils/card_validator.dart';
import '../screens/traveler/profile/widgets/card_visual_widget.dart';
import '../theme/app_colors.dart';

class PaymentService {
  final PaymentRepository _paymentRepo = PaymentRepository();
  final GuideBookingRepository _bookingRepo = GuideBookingRepository();
  final HomestayBookingRepository _homestayBookingRepo =
      HomestayBookingRepository();

  Future<void> processMockPayment({
    required BuildContext context,
    required String bookingId,
    required String bookingType,
    required String userId,
    required double amount,
    required String currency,
    required String description,
    required Function(bool success, String? transactionId) onComplete,
  }) async {
    // Open Mock Payment Screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockPaymentScreen(
          amount: amount,
          currency: currency,
          description: description,
          userId: userId,
        ),
      ),
    );

    if (result == null) {
      // User cancelled
      onComplete(false, null);
      return;
    }

    final now = DateTime.now();
    final mockTxId = result == true
        ? 'TXN-${Random().nextInt(899999) + 100000}'
        : null;

    // Create the Payment record with the outcome
    final payment = PaymentModel(
      id: '',
      bookingId: bookingId,
      bookingType: bookingType,
      userId: userId,
      amount: amount,
      currency: currency,
      status: result == true ? 'paid' : 'failed',
      description: description,
      transactionId: mockTxId,
      paidAt: result == true ? now : null,
    );

    try {
      await _paymentRepo.createPayment(payment);
    } catch (e) {
      debugPrint('Error creating payment record: $e');
      onComplete(false, null);
      return;
    }

    if (result == false) {
      if (bookingType == 'tour_package') {
        await _bookingRepo.updateBookingStatus(
          bookingId,
          'accepted',
          paymentStatus: 'failed',
        );
      } else if (bookingType == 'homestay') {
        await _homestayBookingRepo.updateBookingStatus(
          bookingId,
          'accepted',
          paymentStatus: 'failed',
        );
      }
      onComplete(false, null);
    } else {
      if (bookingType == 'tour_package') {
        await _bookingRepo.updateBookingStatus(
          bookingId,
          'confirmed',
          paymentStatus: 'paid',
          transactionId: mockTxId,
          paidAt: now,
        );

        // Notify traveler and guide via email
        final booking = await _bookingRepo.getBooking(bookingId);
        if (booking != null) {
          EmailService.notifyTravelerPaymentConfirmed(
            toEmail: booking.guestEmail,
            customerName: booking.guestName,
            bookingId: bookingId,
            amount: '$currency $amount',
          );

          FirebaseFirestore.instance
              .collection('users')
              .doc(booking.guideId)
              .get()
              .then((doc) {
            if (doc.exists && doc.data()?['email'] != null) {
              EmailService.notifyHostPaymentReceived(
                hostEmail: doc.data()!['email'],
                hostName: doc.data()?['name'] ?? 'Guide',
                bookingId: bookingId,
                amount: '$currency $amount',
              );
            }
          });
        }
      } else if (bookingType == 'homestay') {
        await _homestayBookingRepo.updateBookingStatus(
          bookingId,
          'confirmed',
          paymentStatus: 'paid',
          transactionId: mockTxId,
          paidAt: now,
        );

        final booking = await _homestayBookingRepo.getBookingById(bookingId);
        if (booking != null) {
          EmailService.notifyTravelerPaymentConfirmed(
            toEmail: booking.travelerEmail,
            customerName: booking.travelerName,
            bookingId: bookingId,
            amount: '$currency $amount',
          );

          FirebaseFirestore.instance
              .collection('users')
              .doc(booking.hostId)
              .get()
              .then((doc) {
            if (doc.exists && doc.data()?['email'] != null) {
              EmailService.notifyHostPaymentReceived(
                hostEmail: doc.data()!['email'],
                hostName: doc.data()?['name'] ?? 'Host',
                bookingId: bookingId,
                amount: '$currency $amount',
              );
            }
          });
        }
      }
      onComplete(true, mockTxId);
    }
  }
}

class MockPaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;
  final String? userId;

  const MockPaymentScreen({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
    this.userId,
  });

  @override
  State<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends State<MockPaymentScreen> {
  final _cardRepo = PaymentCardRepository();

  // Mode: 0 = Saved Cards, 1 = New Card
  int _selectedPaymentMode = 0;

  // Saved Cards state
  List<PaymentCardModel> _savedCards = [];
  PaymentCardModel? _selectedSavedCard;
  final _savedCardCvvController = TextEditingController();
  bool _isLoadingCards = true;

  // New Card Form state
  final _newCardNumberController = TextEditingController();
  final _newHolderNameController = TextEditingController();
  final _newExpiryController = TextEditingController();
  final _newCvvController = TextEditingController();
  String _newSelectedBank = CardValidator.popularSriLankanBanks.first;
  bool _saveNewCardForFuture = true;

  bool _isProcessing = false;
  String? _errorMessage;
  CardBrand _newDetectedBrand = CardBrand.visa;
  String _profileOwnerName = 'RANDIV DULNETH';

  @override
  void initState() {
    super.initState();
    _loadUserCards();
    _newCardNumberController.addListener(_onNewNumberChanged);
  }

  void _onNewNumberChanged() {
    final brand = CardValidator.detectBrand(_newCardNumberController.text);
    if (brand != _newDetectedBrand && brand != CardBrand.unknown) {
      setState(() => _newDetectedBrand = brand);
    }
  }

  @override
  void dispose() {
    _savedCardCvvController.dispose();
    _newCardNumberController.dispose();
    _newHolderNameController.dispose();
    _newExpiryController.dispose();
    _newCvvController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCards() async {
    final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      FirebaseFirestore.instance.collection('users').doc(uid).get().then((doc) {
        if (doc.exists && doc.data() != null) {
          final fullName = doc.data()?['fullName'] as String?;
          if (fullName != null && fullName.trim().isNotEmpty && mounted) {
            setState(() {
              _profileOwnerName = fullName.trim();
              if (_newHolderNameController.text.isEmpty) {
                _newHolderNameController.text = _profileOwnerName.toUpperCase();
              }
            });
          }
        }
      });
    }

    if (uid == null || uid.isEmpty) {
      setState(() {
        _isLoadingCards = false;
        _selectedPaymentMode = 1; // force new card
      });
      return;
    }

    try {
      final cards = await _cardRepo.getCards(uid);
      if (mounted) {
        setState(() {
          _savedCards = cards;
          _isLoadingCards = false;
          if (cards.isNotEmpty) {
            _selectedSavedCard = cards.firstWhere(
              (c) => c.isDefault,
              orElse: () => cards.first,
            );
            _selectedPaymentMode = 0;
          } else {
            _selectedPaymentMode = 1;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCards = false;
          _selectedPaymentMode = 1;
        });
      }
    }
  }

  void _fillTestNewCard(String type) {
    if (type == 'visa') {
      _newDetectedBrand = CardBrand.visa;
      _newCardNumberController.text = '4242 4242 4242 4242';
      _newHolderNameController.text = _profileOwnerName.toUpperCase();
      _newExpiryController.text = '12/28';
      _newCvvController.text = '123';
      _newSelectedBank = 'Commercial Bank of Ceylon';
    } else if (type == 'mastercard') {
      _newDetectedBrand = CardBrand.mastercard;
      _newCardNumberController.text = '5555 5555 5555 5555';
      _newHolderNameController.text = _profileOwnerName.toUpperCase();
      _newExpiryController.text = '09/29';
      _newCvvController.text = '456';
      _newSelectedBank = 'Sampath Bank';
    } else if (type == 'amex') {
      _newDetectedBrand = CardBrand.amex;
      _newCardNumberController.text = '3782 822463 10005';
      _newHolderNameController.text = _profileOwnerName.toUpperCase();
      _newExpiryController.text = '11/27';
      _newCvvController.text = '1234';
      _newSelectedBank = 'Nations Trust Bank (NTB)';
    }
    setState(() {});
  }

  Future<void> _payWithSavedCard() async {
    if (_selectedSavedCard == null) {
      setState(() => _errorMessage = 'Please select a saved card.');
      return;
    }

    if (_selectedSavedCard!.isExpired) {
      setState(() => _errorMessage = 'The selected card has expired. Please choose another card or enter a new one.');
      return;
    }

    final cvv = _savedCardCvvController.text.trim();
    if (cvv.length < 3) {
      setState(() => _errorMessage = 'Please enter a valid 3 or 4-digit CVV to confirm security.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Simulate bank authorization
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _payWithNewCard() async {
    final cleanNumber = _newCardNumberController.text.replaceAll(' ', '');
    final holderName = _newHolderNameController.text.trim();
    final expiry = _newExpiryController.text.trim();
    final cvv = _newCvvController.text.trim();

    if (cleanNumber.length < 15) {
      setState(() => _errorMessage = 'Please enter a valid card number.');
      return;
    }

    if (holderName.length < 3) {
      setState(() => _errorMessage = 'Please enter the cardholder name.');
      return;
    }

    final expiryError = CardValidator.validateExpiryDate(expiry);
    if (expiryError != null) {
      setState(() => _errorMessage = expiryError);
      return;
    }

    final cvvError = CardValidator.validateCVV(cvv, brand: _newDetectedBrand);
    if (cvvError != null) {
      setState(() => _errorMessage = cvvError);
      return;
    }

    // Luhn algorithm or known test cards
    final isKnownTest = ['4242424242424242', '5555555555555555', '378282246310005'].contains(cleanNumber);
    if (!isKnownTest && !CardValidator.validateCardNumber(cleanNumber)) {
      setState(() => _errorMessage = 'Invalid card number checksum. Please check card digits.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(milliseconds: 1800));

    // If user selected to save card for future, save to Firestore
    if (_saveNewCardForFuture) {
      final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        try {
          final expiryParts = expiry.split('/');
          final brandStr = CardValidator.brandToString(_newDetectedBrand);
          final masked = CardValidator.maskCardNumber(cleanNumber);
          final last4 = CardValidator.getLast4(cleanNumber);

          final newCard = PaymentCardModel(
            id: '',
            userId: uid,
            cardHolderName: holderName,
            cardNumberMasked: masked,
            last4: last4,
            cardBrand: brandStr,
            bankName: _newSelectedBank,
            expiryMonth: expiryParts[0].trim(),
            expiryYear: expiryParts[1].trim(),
            colorThemeIndex: 0,
            isDefault: _savedCards.isEmpty,
          );

          await _cardRepo.addCard(newCard);
        } catch (e) {
          debugPrint('Error saving card during payment: $e');
        }
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Secure Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0.5,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFBF7EE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Summary Box
            _buildOrderSummaryCard(),

            const SizedBox(height: 20),

            // Mode Selector: Saved Cards vs New Card
            if (!_isLoadingCards && _savedCards.isNotEmpty) ...[
              _buildModeSelector(),
              const SizedBox(height: 16),
            ],

            // Content based on Mode
            if (_isLoadingCards)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_selectedPaymentMode == 0 && _savedCards.isNotEmpty)
              _buildSavedCardsSection()
            else
              _buildNewCardSection(),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Pay Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : (_selectedPaymentMode == 0 && _savedCards.isNotEmpty
                        ? _payWithSavedCard
                        : _payWithNewCard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing Payment...',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : Text(
                        'Pay ${widget.currency} ${NumberFormat('#,##0').format(widget.amount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Security Badge
            _buildSecurityBadge(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Village Tour Sri Lanka',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const Divider(height: 24, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${widget.currency} ${NumberFormat('#,##0.00').format(widget.amount)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F4D3A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECE7D6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPaymentMode = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedPaymentMode == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedPaymentMode == 0
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 18,
                      color: _selectedPaymentMode == 0 ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Saved Cards (${_savedCards.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedPaymentMode == 0 ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPaymentMode = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedPaymentMode == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedPaymentMode == 1
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: _selectedPaymentMode == 1 ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'New Card',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedPaymentMode == 1 ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Card',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 12),

        // Carousel / List of Cards
        ..._savedCards.map((card) {
          final isSelected = _selectedSavedCard?.id == card.id;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSavedCard = card;
                _savedCardCvvController.clear();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1F4D3A) : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1F4D3A).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  CardVisualWidget(
                    bankName: card.bankName,
                    cardHolderName: card.cardHolderName,
                    cardNumber: card.cardNumberMasked,
                    expiry: card.formattedExpiry,
                    cardBrand: card.cardBrand,
                    cardType: card.cardType,
                    themeIndex: card.colorThemeIndex,
                    isDefault: card.isDefault,
                  ),
                  if (isSelected)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF1F4D3A),
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 12),

        // Security CVV prompt for chosen card
        if (_selectedSavedCard != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security Code (CVV)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '3 digits on back of ${_selectedSavedCard!.bankName}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _savedCardCvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '•••',
                      filled: true,
                      fillColor: const Color(0xFFFBF7EE),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNewCardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Card Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Row(
                children: [
                  _buildNetworkChip('Visa', CardBrand.visa, () => _fillTestNewCard('visa')),
                  const SizedBox(width: 5),
                  _buildNetworkChip('Mastercard', CardBrand.mastercard, () => _fillTestNewCard('mastercard')),
                  const SizedBox(width: 5),
                  _buildNetworkChip('Amex', CardBrand.amex, () => _fillTestNewCard('amex')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bank Selector
          const Text(
            'Bank Name',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _newSelectedBank,
                items: CardValidator.popularSriLankanBanks.map((bank) {
                  return DropdownMenuItem(value: bank, child: Text(bank, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _newSelectedBank = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Card Number
          const Text(
            'Card Number',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _newCardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [CardNumberInputFormatter()],
            decoration: InputDecoration(
              hintText: '4242 4242 4242 4242',
              prefixIcon: const Icon(Icons.credit_card, size: 20, color: AppColors.primary),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildBrandSuffixBadge(_newDetectedBrand),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 12),

          // Cardholder Name
          const Text(
            'Cardholder Name',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _newHolderNameController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'RANDIV DULNETH',
              prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 12),

          // Expiry & CVV
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expiry Date',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _newExpiryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CardExpiryInputFormatter()],
                      decoration: InputDecoration(
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CVV',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _newCvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: _newDetectedBrand == CardBrand.amex ? 4 : 3,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '•••',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Save card checkbox
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            value: _saveNewCardForFuture,
            onChanged: (val) => setState(() => _saveNewCardForFuture = val ?? true),
            title: const Text(
              'Save this card for future bookings',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkChip(String label, CardBrand brand, VoidCallback onTap) {
    final bool isSelected = _newDetectedBrand == brand;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F4D3A) : const Color(0xFFECE7D6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_circle, size: 11, color: Color(0xFFD4AF37)),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandSuffixBadge(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return const Text('VISA', style: TextStyle(color: Color(0xFF1A1F71), fontStyle: FontStyle.italic, fontWeight: FontWeight.w900));
      case CardBrand.mastercard:
        return const Text('MC', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
      case CardBrand.amex:
        return const Text('AMEX', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold));
      default:
        return const Icon(Icons.credit_card, size: 18, color: Colors.grey);
    }
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF2E7D32), size: 16),
          SizedBox(width: 6),
          Text(
            'Bank-Grade 256-Bit SSL Encrypted Payment',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
