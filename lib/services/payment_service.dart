import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/payment.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/guide_booking_repository.dart';
import '../../repositories/homestay_booking_repository.dart';

import 'dart:math';

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
    // Open Mock Payment Screen IMMEDIATELY
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockPaymentScreen(
          amount: amount,
          currency: currency,
          description: description,
        ),
      ),
    );

    if (result == null) {
      // User cancelled the payment by going back.
      // Leave it as 'unpaid', no need to update booking.
      onComplete(false, null);
      return;
    }

    final now = DateTime.now();
    final mockTxId = result == true
        ? 'MOCK-${Random().nextInt(999999).toString().padLeft(6, '0')}'
        : null;

    // Create the Payment record with the final outcome
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
      // Payment explicitly failed
      if (bookingType == 'tour_package') {
        await _bookingRepo.updateBookingStatus(
          bookingId,
          'accepted', // keep it accepted
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
      // Payment success
      if (bookingType == 'tour_package') {
        await _bookingRepo.updateBookingStatus(
          bookingId,
          'confirmed',
          paymentStatus: 'paid',
          transactionId: mockTxId,
          paidAt: now,
        );
      } else if (bookingType == 'homestay') {
        await _homestayBookingRepo.updateBookingStatus(
          bookingId,
          'confirmed',
          paymentStatus: 'paid',
          transactionId: mockTxId,
          paidAt: now,
        );
      }
      onComplete(true, mockTxId);
    }
  }
}

class MockPaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;

  const MockPaymentScreen({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
  });

  @override
  State<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends State<MockPaymentScreen> {
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;
  String? _errorMessage;

  void _processPayment() async {
    // Basic form validation
    if (_cardNumberController.text.replaceAll(' ', '').length < 15 ||
        _holderNameController.text.isEmpty ||
        _expiryController.text.length != 5 ||
        _cvvController.text.length < 3) {
      setState(() {
        _errorMessage = 'Please enter valid card details.';
      });
      return;
    }

    // Expiry date validation
    final expiryParts = _expiryController.text.split('/');
    if (expiryParts.length == 2) {
      final month = int.tryParse(expiryParts[0]) ?? 0;
      final year = int.tryParse(expiryParts[1]) ?? 0;

      if (month < 1 || month > 12) {
        setState(() {
          _errorMessage = 'Please enter a valid expiry month.';
        });
        return;
      }

      final now = DateTime.now();
      final currentYear = now.year % 100;
      final currentMonth = now.month;

      if (year < currentYear || (year == currentYear && month < currentMonth)) {
        setState(() {
          _errorMessage = 'Card has expired. Please use a valid card.';
        });
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final validCards = [
      '4242424242424242', // Visa
      '5555555555555555', // Mastercard
      '378282246310005', // Amex
    ];

    if (validCards.contains(cardNumber)) {
      // Success
      Navigator.pop(context, true);
    } else {
      // Failure
      setState(() {
        _isProcessing = false;
        _errorMessage =
            'Your payment could not be completed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Booking Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Summary',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${widget.currency} ${NumberFormat('#,##0.00').format(widget.amount)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Form
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.credit_card, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Credit / Debit Card',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      hintText: '4242 4242 4242 4242',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CardNumberFormatter()],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _holderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Card Holder Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            hintText: 'MM/YY',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [ExpiryDateFormatter()],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            hintText: '123',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Pay ${widget.currency} ${NumberFormat('#,##0').format(widget.amount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Security Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '100% Secure Payment',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Supported Cards
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Supported by: ',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(width: 8),
                Text(
                  'VISA',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Text('•', style: TextStyle(color: Colors.grey, fontSize: 14)),
                SizedBox(width: 8),
                Text(
                  'Mastercard',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Text('•', style: TextStyle(color: Colors.grey, fontSize: 14)),
                SizedBox(width: 8),
                Text(
                  'AMEX',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 16) return oldValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 4) return oldValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
