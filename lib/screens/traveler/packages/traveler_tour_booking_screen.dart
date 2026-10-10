import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../models/tour_package.dart';
import '../../../models/guide_booking.dart';
import '../../../repositories/guide_booking_repository.dart';
import '../../../services/email_service.dart';

class TravelerTourBookingScreen extends StatefulWidget {
  final TourPackage package;

  const TravelerTourBookingScreen({super.key, required this.package});

  @override
  State<TravelerTourBookingScreen> createState() =>
      _TravelerTourBookingScreenState();
}

class _TravelerTourBookingScreenState extends State<TravelerTourBookingScreen> {
  final GuideBookingRepository _bookingRepo = GuideBookingRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _selectedDate;
  DateTime? _calculatedEndDate;
  int _guestCount = 1;
  bool _isCheckingAvailability = false;
  bool _isSubmitting = false;

  late DateTime _focusedMonth;
  List<GuideBooking> _existingBookings = [];
  bool _isLoadingBookings = true;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('guide_bookings')
          .where('packageId', isEqualTo: widget.package.id)
          .where('status', whereIn: ['pending', 'accepted', 'confirmed'])
          .get();

      if (mounted) {
        setState(() {
          _existingBookings = snapshot.docs
              .map((doc) => GuideBooking.fromMap(doc.data(), doc.id))
              .toList();
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings for calendar: $e');
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _focusedMonth = month;
    });
  }

  bool _isDateSelectable(DateTime date) {
    // 1. Not in the past (only today or future)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today)) return false;

    // 2. Matches package available days
    final weekdayStr = _getWeekdayString(date.weekday);
    if (widget.package.availableDays[weekdayStr] != true) return false;

    // 3. Not in blackout dates
    for (var blackout in widget.package.unavailableDates) {
      if (blackout.year == date.year &&
          blackout.month == date.month &&
          blackout.day == date.day) {
        return false;
      }
    }

    return true;
  }

  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return '';
    }
  }

  Future<void> _handleDateSelection(DateTime date) async {
    if (!_isDateSelectable(date)) return;

    setState(() {
      _selectedDate = date;
      // Duration logic: if duration is 4 days, end date is start date + 3 days
      _calculatedEndDate = date.add(
        Duration(
          days: widget.package.durationDays > 0
              ? widget.package.durationDays - 1
              : 0,
        ),
      );
      _isCheckingAvailability = true;
    });

    // 4. Check for overlapping bookings
    try {
      final isOverlap = await _bookingRepo.checkDateOverlap(
        widget.package.id,
        _selectedDate!,
        _calculatedEndDate!,
      );
      if (isOverlap && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The selected date range is unavailable due to an existing booking.',
            ),
          ),
        );
        setState(() {
          _selectedDate = null;
          _calculatedEndDate = null;
        });
      }
    } catch (e) {
      debugPrint('Error checking availability: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
        });
      }
    }
  }

  void _submitBooking() async {
    if (_selectedDate == null || _calculatedEndDate == null) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in to book.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Re-verify overlap just in case
      final isOverlap = await _bookingRepo.checkDateOverlap(
        widget.package.id,
        _selectedDate!,
        _calculatedEndDate!,
      );
      if (isOverlap) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dates are no longer available.')),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = doc.data() ?? {};

      final booking = GuideBooking(
        id: '',
        guideId: widget.package.guideId,
        packageId: widget.package.id,
        packageTitle: widget.package.title,
        guestId: user.uid,
        guestName: userData['fullName'] ?? userData['name'] ?? user.displayName ?? 'Traveler',
        guestEmail: userData['email'] ?? user.email ?? '',
        guestPhone: userData['phoneNumber'],
        guestProfileUrl: userData['profileImageUrl'],
        startDate: _selectedDate!,
        endDate: _calculatedEndDate!,
        numberOfGuests: _guestCount,
        totalPrice: widget.package.pricePerGuest * _guestCount,
        status: 'pending',
        paymentStatus: 'unpaid',
      );

      final newBookingId = await _bookingRepo.createBooking(booking);

      // ✉️ Send Emails
      EmailService.notifyTravelerBookingRequested(
        toEmail: booking.guestEmail,
        customerName: booking.guestName,
        bookingId: newBookingId,
        type: 'Tour',
      );

      // Fetch guide details to send email
      FirebaseFirestore.instance.collection('users').doc(booking.guideId).get().then((doc) {
        if (doc.exists) {
          final guideEmail = doc.data()?['email'];
          final guideName = doc.data()?['name'] ?? doc.data()?['fullName'] ?? 'Guide';
          if (guideEmail != null) {
            EmailService.notifyHostNewBookingRequest(
              hostEmail: guideEmail,
              hostName: guideName,
              bookingId: newBookingId,
              travelerName: booking.guestName,
              dates: '${DateFormat('MMM dd').format(booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(booking.endDate)}',
            );
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking request sent!')));
        Navigator.pop(context); // Go back to details
      }
    } catch (e) {
      debugPrint('Booking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit booking.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun

    List<Widget> dayWidgets = [];

    // Empty slots for previous month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Days of current month
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, i);
      final bookingStatus = _getBookingStatusForDate(date);
      final isSelectable = _isDateSelectable(date) && bookingStatus == null;
      final isSelected =
          _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;

      BoxDecoration decoration = const BoxDecoration();
      Color textColor = Colors.black87;

      if (isSelected) {
        decoration = const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        );
        textColor = Colors.white;
      } else if (bookingStatus != null) {
        if (bookingStatus == 'pending') {
          decoration = BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          );
          textColor = Colors.orange.shade800;
        } else {
          // accepted or confirmed (booked)
          decoration = BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          );
          textColor = Colors.red.shade800;
        }
      } else if (!isSelectable) {
        textColor = Colors.grey.shade400;
      } else if (date.isAtSameMomentAs(today)) {
        decoration = BoxDecoration(
          border: Border.all(color: AppColors.primary),
          shape: BoxShape.circle,
        );
      }

      dayWidgets.add(
        GestureDetector(
          onTap: isSelectable ? () => _handleDateSelection(date) : null,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: decoration,
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _onMonthChanged(
                  DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1),
                );
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(_focusedMonth),
              style: AppTextStyles.labelLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _onMonthChanged(
                  DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ...dayWidgets,
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingBookings)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(Colors.black87, 'Available', isOutlined: true),
              _buildLegendItem(Colors.red.withValues(alpha: 0.5), 'Booked'),
              _buildLegendItem(Colors.orange.withValues(alpha: 0.5), 'Pending'),
              _buildLegendItem(Colors.grey.shade300, 'Unavailable'),
            ],
          ),
      ],
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label, {
    bool isOutlined = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOutlined ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isOutlined ? Border.all(color: Colors.grey.shade400) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  String? _getBookingStatusForDate(DateTime date) {
    for (var booking in _existingBookings) {
      final start = DateTime(
        booking.startDate.year,
        booking.startDate.month,
        booking.startDate.day,
      );
      final end = DateTime(
        booking.endDate.year,
        booking.endDate.month,
        booking.endDate.day,
      );
      final current = DateTime(date.year, date.month, date.day);

      if (!current.isBefore(start) && !current.isAfter(end)) {
        return booking.status;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final double totalPrice = widget.package.pricePerGuest * _guestCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Tour'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        titleTextStyle: AppTextStyles.screenHeading.copyWith(
          color: AppColors.primaryDark,
          fontSize: 20,
        ),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Start Date', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _buildCalendar(),
            ),

            if (_isCheckingAvailability)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 24),

            if (_selectedDate != null && !_isCheckingAvailability) ...[
              Text('Booking Details', style: AppTextStyles.sectionHeading),
              const SizedBox(height: 8),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Start: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'End: ${DateFormat('dd MMM yyyy').format(_calculatedEndDate!)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: ${widget.package.durationDays} Days / ${widget.package.nights} Nights',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Guests', style: AppTextStyles.sectionHeading),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _guestCount > 1
                        ? () => setState(() => _guestCount--)
                        : null,
                  ),
                  Text(
                    '$_guestCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _guestCount < widget.package.maxGuests
                        ? () => setState(() => _guestCount++)
                        : null,
                  ),
                  const Spacer(),
                  Text(
                    'Max: ${widget.package.maxGuests}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Price per Guest'),
                        Text(
                          'Rs. ${NumberFormat('#,##0').format(widget.package.pricePerGuest)}',
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Rs. ${NumberFormat('#,##0').format(totalPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Request Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
