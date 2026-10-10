import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../models/homestay.dart';
import '../../../../models/homestay_booking.dart';
import '../../../../repositories/homestay_booking_repository.dart';
import '../../../../services/email_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class HomestayBookingSheet extends StatefulWidget {
  final Homestay homestay;

  const HomestayBookingSheet({super.key, required this.homestay});

  @override
  State<HomestayBookingSheet> createState() => _HomestayBookingSheetState();
}

class _HomestayBookingSheetState extends State<HomestayBookingSheet> {
  final _bookingRepo = HomestayBookingRepository();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 1;
  final List<Map<String, dynamic>> _selectedAddOns = [];

  bool _isSubmitting = false;
  String? _availabilityError;

  @override
  Widget build(BuildContext context) {
    int nights = 0;
    double accommodationAmount = 0;
    if (_checkInDate != null && _checkOutDate != null) {
      nights = _checkOutDate!.difference(_checkInDate!).inDays;
      if (nights <= 0) nights = 0;
      accommodationAmount = nights * widget.homestay.pricePerNight;
    }

    double addOnAmount = 0;
    for (var addon in _selectedAddOns) {
      addOnAmount += addon['price'] * addon['quantity'];
    }

    double totalAmount = accommodationAmount + addOnAmount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateSelection(),
                    if (_availabilityError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _availabilityError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildGuestSelection(),
                    const SizedBox(height: AppSpacing.lg),
                    if (widget.homestay.optionalAddOns.isNotEmpty) ...[
                      _buildAddOnsSelection(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (nights > 0)
                      _buildPriceBreakdown(
                        nights,
                        accommodationAmount,
                        addOnAmount,
                        totalAmount,
                      ),
                  ],
                ),
              ),
            ),
            _buildFooter(nights, totalAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Request to Book',
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.primaryDark,
              fontSize: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildSelector(
            label: 'CHECK-IN',
            value: _checkInDate != null
                ? DateFormat('MMM dd, yyyy').format(_checkInDate!)
                : 'Select Date',
            onTap: () => _selectDate(true),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildSelector(
            label: 'CHECK-OUT',
            value: _checkOutDate != null
                ? DateFormat('MMM dd, yyyy').format(_checkOutDate!)
                : 'Select Date',
            onTap: () => _selectDate(false),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestSelection() {
    return _buildSelector(
      label: 'GUESTS',
      value: '$_guestCount Guest${_guestCount > 1 ? 's' : ''}',
      onTap: _showGuestPicker,
    );
  }

  Widget _buildSelector({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOnsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optional Add-ons',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.homestay.optionalAddOns.map((addon) {
          final isSelected = _selectedAddOns.any(
            (a) => a['title'] == addon['title'],
          );
          return CheckboxListTile(
            title: Text(addon['title']),
            subtitle: Text('Rs. ${addon['price']} per person'),
            value: isSelected,
            activeColor: AppColors.primaryDark,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedAddOns.add({
                    'title': addon['title'],
                    'price': addon['price'],
                    'quantity': _guestCount,
                  });
                } else {
                  _selectedAddOns.removeWhere(
                    (a) => a['title'] == addon['title'],
                  );
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildPriceBreakdown(
    int nights,
    double accAmt,
    double addOnAmt,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rs. ${widget.homestay.pricePerNight} x $nights nights'),
              Text('Rs. $accAmt'),
            ],
          ),
          if (addOnAmt > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('Add-ons'), Text('Rs. $addOnAmt')],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total (LKR)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Rs. $total',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int nights, double totalAmount) {
    final isValid =
        _checkInDate != null &&
        _checkOutDate != null &&
        nights > 0 &&
        _availabilityError == null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isValid && !_isSubmitting
            ? () => _submitRequest(totalAmount, nights)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Send Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkInDate ?? DateTime.now().add(const Duration(days: 1)))
          : (_checkOutDate ??
                (_checkInDate?.add(const Duration(days: 1)) ??
                    DateTime.now().add(const Duration(days: 2)))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (day) {
        // Block unavailable dates
        for (var unavailable in widget.homestay.unavailableDates) {
          if (day.year == unavailable.year &&
              day.month == unavailable.month &&
              day.day == unavailable.day) {
            return false;
          }
        }

        // Block weekly recurring unavailable days
        final weekday = DateFormat('EEEE').format(day).toLowerCase();
        if (widget.homestay.availableDays[weekday] == false) {
          return false;
        }

        return true;
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && !_checkOutDate!.isAfter(_checkInDate!)) {
            _checkOutDate =
                null; // Reset checkout if it's before or equal to new checkin
          }
        } else {
          _checkOutDate = picked;
          if (_checkInDate != null && !_checkOutDate!.isAfter(_checkInDate!)) {
            _checkInDate =
                null; // Reset checkin if it's after or equal to new checkout
          }
        }
        _availabilityError = null; // Reset error when dates change
      });

      if (_checkInDate != null && _checkOutDate != null) {
        _checkAvailability();
      }
    }
  }

  void _showGuestPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        int tempGuests = _guestCount;
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Guests',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Adults & Children'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: tempGuests > 1
                                ? () => setStateSB(() => tempGuests--)
                                : null,
                          ),
                          Text(
                            '$tempGuests',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: tempGuests < widget.homestay.maxGuests
                                ? () => setStateSB(() => tempGuests++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _guestCount = tempGuests;
                          // Update quantity for add-ons
                          for (var addon in _selectedAddOns) {
                            addon['quantity'] = _guestCount;
                          }
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _availabilityError = null;
    });

    try {
      final activeBookings = await _bookingRepo.getActiveBookingsForHomestay(
        widget.homestay.id,
      );

      bool overlap = false;
      for (var b in activeBookings) {
        if (_checkInDate!.isBefore(b.checkOutDate) &&
            _checkOutDate!.isAfter(b.checkInDate)) {
          overlap = true;
          break;
        }
      }

      if (overlap) {
        setState(() {
          _availabilityError =
              'These dates are already booked. Please select different dates.';
        });
      }
    } catch (e) {
      debugPrint('Error checking availability: $e');
    }
  }

  Future<void> _submitRequest(double totalAmount, int nights) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) throw Exception('User profile not found');
      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['fullName'] ?? userData['name'] ?? 'Traveler';
      final userEmail = userData['email'] ?? user.email ?? '';

      final booking = HomestayBooking(
        id: '',
        homestayId: widget.homestay.id,
        homestayTitle: widget.homestay.title,
        hostId: widget.homestay.hostId,
        travelerId: user.uid,
        travelerName: userName,
        travelerEmail: userEmail,
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        numberOfNights: nights,
        guestCount: _guestCount,
        pricePerNight: widget.homestay.pricePerNight,
        accommodationAmount: widget.homestay.pricePerNight * nights,
        addOnAmount: totalAmount - (widget.homestay.pricePerNight * nights),
        totalAmount: totalAmount,
        selectedAddOns: _selectedAddOns,
        bookingStatus: 'pending',
      );

      final newBookingId = await _bookingRepo.createBooking(booking);

      // ✉️ Send Emails
      EmailService.notifyTravelerBookingRequested(
        toEmail: booking.travelerEmail,
        customerName: booking.travelerName,
        bookingId: newBookingId,
        type: 'Homestay',
      );

      // Fetch host details to send email
      FirebaseFirestore.instance.collection('users').doc(booking.hostId).get().then((doc) {
        if (doc.exists) {
          final hostEmail = doc.data()?['email'];
          final hostName = doc.data()?['name'] ?? doc.data()?['fullName'] ?? 'Host';
          if (hostEmail != null) {
            EmailService.notifyHostNewBookingRequest(
              hostEmail: hostEmail,
              hostName: hostName,
              bookingId: newBookingId,
              travelerName: booking.travelerName,
              dates: '${DateFormat('MMM dd').format(booking.checkInDate)} - ${DateFormat('MMM dd, yyyy').format(booking.checkOutDate)}',
            );
          }
        }
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request sent to host!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
