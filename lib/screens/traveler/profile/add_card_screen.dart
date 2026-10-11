import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../models/payment_card.dart';
import '../../../repositories/payment_card_repository.dart';
import '../../../utils/card_validator.dart';
import 'widgets/card_visual_widget.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardRepo = PaymentCardRepository();

  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String _selectedBank = CardValidator.popularSriLankanBanks.first;
  String _cardType = 'Debit';
  int _selectedThemeIndex = 0;
  bool _isDefault = true;
  bool _isSaving = false;

  CardBrand _detectedBrand = CardBrand.visa;
  String _profileOwnerName = 'RANDIV DULNETH';

  @override
  void initState() {
    super.initState();
    _fetchProfileOwnerName();
    _numberController.addListener(_onNumberChanged);
    _nameController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
  }

  Future<void> _fetchProfileOwnerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _profileOwnerName = user.displayName!.trim();
            if (_nameController.text.isEmpty) {
              _nameController.text = _profileOwnerName.toUpperCase();
            }
          });
        }
      }
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final fullName = doc.data()?['fullName'] as String?;
          if (fullName != null && fullName.trim().isNotEmpty && mounted) {
            setState(() {
              _profileOwnerName = fullName.trim();
              if (_nameController.text.isEmpty ||
                  _nameController.text == 'RANDIV DULNETH') {
                _nameController.text = _profileOwnerName.toUpperCase();
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching profile owner name: $e');
      }
    }
  }

  void _onNumberChanged() {
    final brand = CardValidator.detectBrand(_numberController.text);
    if (brand != _detectedBrand) {
      setState(() {
        _detectedBrand = brand;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _selectNetwork(CardBrand brand) {
    setState(() {
      _detectedBrand = brand;
    });
    if (brand == CardBrand.visa) {
      _fillTestData('visa');
    } else if (brand == CardBrand.mastercard) {
      _fillTestData('mastercard');
    } else if (brand == CardBrand.amex) {
      _fillTestData('amex');
    }
  }

  void _fillTestData(String type) {
    if (type == 'visa') {
      _detectedBrand = CardBrand.visa;
      _numberController.text = '4242 4242 4242 4242';
      _nameController.text = _profileOwnerName.toUpperCase();
      _expiryController.text = '12/28';
      _cvvController.text = '123';
      _selectedBank = 'Commercial Bank of Ceylon';
      _cardType = 'Debit';
      _selectedThemeIndex = 0;
    } else if (type == 'mastercard') {
      _detectedBrand = CardBrand.mastercard;
      _numberController.text = '5555 5555 5555 5555';
      _nameController.text = _profileOwnerName.toUpperCase();
      _expiryController.text = '08/29';
      _cvvController.text = '456';
      _selectedBank = 'Sampath Bank';
      _cardType = 'Credit';
      _selectedThemeIndex = 2;
    } else if (type == 'amex') {
      _detectedBrand = CardBrand.amex;
      _numberController.text = '3782 822463 10005';
      _nameController.text = _profileOwnerName.toUpperCase();
      _expiryController.text = '10/27';
      _cvvController.text = '1234';
      _selectedBank = 'Nations Trust Bank (NTB)';
      _cardType = 'Credit';
      _selectedThemeIndex = 3;
    }
    setState(() {});
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save card details.')),
      );
      return;
    }

    // Deep Validation: Luhn algorithm check
    final cleanNumber = _numberController.text.replaceAll(' ', '');
    final isLuhnValid = CardValidator.validateCardNumber(cleanNumber);
    if (!isLuhnValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid card number checksum. Please check the digits.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final expiryParts = _expiryController.text.split('/');
      final brandStr = CardValidator.brandToString(_detectedBrand);
      final masked = CardValidator.maskCardNumber(cleanNumber);
      final last4 = CardValidator.getLast4(cleanNumber);

      final newCard = PaymentCardModel(
        id: '',
        userId: currentUser.uid,
        cardHolderName: _nameController.text.trim(),
        cardNumberMasked: masked,
        last4: last4,
        cardBrand: brandStr,
        cardType: _cardType,
        bankName: _selectedBank,
        expiryMonth: expiryParts[0].trim(),
        expiryYear: expiryParts[1].trim(),
        colorThemeIndex: _selectedThemeIndex,
        isDefault: _isDefault,
      );

      await _cardRepo.addCard(newCard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card saved successfully!'),
            backgroundColor: Color(0xFF1F4D3A),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save card: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add Payment Card',
          style: AppTextStyles.screenHeading.copyWith(fontSize: 20),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Interactive Card Visual Preview
              CardVisualWidget(
                bankName: _selectedBank,
                cardHolderName: _nameController.text.trim().isEmpty
                    ? _profileOwnerName.toUpperCase()
                    : _nameController.text.toUpperCase(),
                cardNumber: _numberController.text.isEmpty
                    ? '•••• •••• •••• ••••'
                    : _numberController.text,
                expiry: _expiryController.text.isEmpty
                    ? 'MM/YY'
                    : _expiryController.text,
                cardBrand: CardValidator.brandToString(_detectedBrand),
                cardType: _cardType,
                themeIndex: _selectedThemeIndex,
                isDefault: _isDefault,
                showFullNumber: true,
              ),

              const SizedBox(height: AppSpacing.md),

              // Card Network Selection & Indication
              Row(
                children: [
                  const Text(
                    'Card Network:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildNetworkSelectorChip(
                    label: 'Visa',
                    brand: CardBrand.visa,
                    onTap: () => _selectNetwork(CardBrand.visa),
                  ),
                  const SizedBox(width: 8),
                  _buildNetworkSelectorChip(
                    label: 'Mastercard',
                    brand: CardBrand.mastercard,
                    onTap: () => _selectNetwork(CardBrand.mastercard),
                  ),
                  const SizedBox(width: 8),
                  _buildNetworkSelectorChip(
                    label: 'Amex',
                    brand: CardBrand.amex,
                    onTap: () => _selectNetwork(CardBrand.amex),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Card Customization: Color Theme Selector
              const Text(
                'Card Styling & Theme',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CardVisualThemes.themes.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final theme = CardVisualThemes.themes[index];
                    final isSelected = _selectedThemeIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedThemeIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: theme.gradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 16),
                              ),
                            Text(
                              theme.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Bank Name Selector
              const Text(
                'Issuing Bank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedBank,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                    items: CardValidator.popularSriLankanBanks.map((bank) {
                      return DropdownMenuItem<String>(
                        value: bank,
                        child: Text(
                          bank,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedBank = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Card Number Input Field
              const Text(
                'Card Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                inputFormatters: [CardNumberInputFormatter()],
                decoration: InputDecoration(
                  hintText: '4242 •••• •••• 4242',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.credit_card_outlined, color: AppColors.primary),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildBrandSuffixBadge(_detectedBrand),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter card number';
                  }
                  final clean = val.replaceAll(' ', '');
                  if (clean.length < 15 || clean.length > 19) {
                    return 'Card number must be 15-16 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Cardholder Name Input Field
              const Text(
                'Cardholder Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. ${_profileOwnerName.toUpperCase()}',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: CardValidator.validateHolderName,
              ),

              const SizedBox(height: AppSpacing.md),

              // Expiry Date & CVV Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expiry Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expiry Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CardExpiryInputFormatter()],
                          decoration: InputDecoration(
                            hintText: 'MM/YY',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                          validator: CardValidator.validateExpiryDate,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // CVV
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Security Code',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: '3-digit CVV on back of card (4 digits for Amex). Never stored.',
                              child: const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: _detectedBrand == CardBrand.amex ? 4 : 3,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: _detectedBrand == CardBrand.amex ? '1234' : '123',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                          validator: (val) => CardValidator.validateCVV(val, brand: _detectedBrand),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Card Type (Debit / Credit)
              Row(
                children: [
                  const Text(
                    'Card Classification:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Debit'),
                    selected: _cardType == 'Debit',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _cardType == 'Debit' ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _cardType = 'Debit');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Credit'),
                    selected: _cardType == 'Credit',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _cardType == 'Credit' ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _cardType = 'Credit');
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Set as default switch
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.primary,
                title: const Text(
                  'Set as primary payment card',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                subtitle: const Text(
                  'Automatically used for one-tap tour & homestay bookings',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Security Assurance Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7DEC9)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Encrypted with bank-grade 256-bit AES. Your security code (CVV) is never stored.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Text(
                          'Save & Secure Card',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkSelectorChip({
    required String label,
    required CardBrand brand,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _detectedBrand == brand;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F4D3A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1F4D3A).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle,
                size: 14,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                letterSpacing: 0.3,
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
        return const Text(
          'VISA',
          style: TextStyle(
            color: Color(0xFF1A1F71),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        );
      case CardBrand.mastercard:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            Transform.translate(
              offset: const Offset(-5, 0),
              child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
            ),
          ],
        );
      case CardBrand.amex:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: const Color(0xFF006FCF),
          child: const Text('AMEX', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        );
      default:
        return const Icon(Icons.credit_card, color: AppColors.textSecondary, size: 20);
    }
  }
}
