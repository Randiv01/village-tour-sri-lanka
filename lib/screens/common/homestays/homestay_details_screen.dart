import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../auth/auth_guard.dart';
import '../../../../models/homestay.dart';
import '../../../../models/homestay_booking.dart';
import '../../../../repositories/homestay_repository.dart';
import '../../../../repositories/homestay_booking_repository.dart';
import '../auth/sign_in_screen.dart';
import '../../traveler/chat/traveler_host_chat_screen.dart';
import 'homestay_reviews_screen.dart';

enum DateState { available, booked, pending, unavailable, past }
class HomestayDetailsScreen extends StatefulWidget {
  final String homestayId;

  const HomestayDetailsScreen({
    super.key,
    required this.homestayId,
  });

  @override
  State<HomestayDetailsScreen> createState() => _HomestayDetailsScreenState();
}

class _HomestayDetailsScreenState extends State<HomestayDetailsScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  final _homestayRepo = HomestayRepository();
  final _bookingRepo = HomestayBookingRepository();

  Homestay? _homestay;
  Map<String, dynamic>? _hostData;
  List<HomestayBooking> _activeBookings = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  int _activeTabIndex = 0;
  int _selectedTabIndex = 0;
  String? _error;

  // Booking states
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 1;
  final List<Map<String, dynamic>> _selectedAddOns = [];
  bool _isSubmitting = false;
  String? _availabilityError;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadHomestay();
  }

  Future<void> _loadHomestay() async {
    try {
      final h = await _homestayRepo.getHomestayById(widget.homestayId);
      if (h == null) throw Exception('Homestay not found');
      final bookings = await _bookingRepo.getActiveBookingsForHomestay(widget.homestayId);
      
      Map<String, dynamic>? hostData;
      try {
        final hostDoc = await FirebaseFirestore.instance.collection('users').doc(h.hostId).get();
        if (hostDoc.exists) hostData = hostDoc.data();
      } catch (_) {}

      bool isFav = false;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final favs = List<String>.from(userDoc.data()?['favorites'] ?? []);
            isFav = favs.contains(h.id);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _homestay = h;
          _hostData = hostData;
          _activeBookings = bookings;
          _isFavorite = isFav;
          _isLoading = false;

          // Auto-select dates starting from today if available
          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          DateTime check = today;
          for (int i = 0; i < 60; i++) {
            final nextDay = check.add(const Duration(days: 1));
            if (_isDateAvailable(check) && _isDateAvailable(nextDay)) {
              _checkInDate = check;
              _checkOutDate = nextDay;
              _currentMonth = DateTime(check.year, check.month, 1);
              break;
            }
            check = nextDay;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _homestay == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to favorite.')));
      return;
    }
    final newFav = !_isFavorite;
    setState(() => _isFavorite = newFav);
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      if (newFav) {
        await userRef.update({'favorites': FieldValue.arrayUnion([_homestay!.id])});
      } else {
        await userRef.update({'favorites': FieldValue.arrayRemove([_homestay!.id])});
      }
    } catch (e) {
      setState(() => _isFavorite = !newFav);
    }
  }

  void _shareHomestay() {
    if (_homestay == null) return;
    // ignore: deprecated_member_use
    Share.share('Village Tour Sri Lanka\n\nHomestay:\n${_homestay!.title}\n\nLocation:\n${_homestay!.location}\n\nPrice:\nRs. ${_homestay!.pricePerNight} / night\n\nExplore this homestay on Village Tour Sri Lanka.');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenGallery() {
    if (_homestay == null || _homestay!.images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGallery(
          images: _homestay!.images,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  bool _isDateAvailable(DateTime day) {
    return _getDateState(day) == DateState.available;
  }

  DateState _getDateState(DateTime day) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (day.isBefore(today)) return DateState.past;
    
    for (var d in _homestay!.unavailableDates) {
      if (d.year == day.year && d.month == day.month && d.day == day.day) return DateState.unavailable;
    }
    
    final weekday = DateFormat('EEEE').format(day).toLowerCase();
    if (_homestay!.availableDays[weekday] == false) return DateState.unavailable;

    for (var b in _activeBookings) {
      final bIn = DateTime(b.checkInDate.year, b.checkInDate.month, b.checkInDate.day);
      final bOut = DateTime(b.checkOutDate.year, b.checkOutDate.month, b.checkOutDate.day);
      if ((day.isAfter(bIn) || day.isAtSameMomentAs(bIn)) && day.isBefore(bOut)) {
        if (b.bookingStatus == 'pending') return DateState.pending;
        return DateState.booked;
      }
    }
    return DateState.available;
  }

  void _onDayTapped(DateTime day) {
    if (!_isDateAvailable(day)) return;

    setState(() {
      if (_checkInDate == null) {
        _checkInDate = day;
      } else if (_checkInDate != null && _checkOutDate == null) {
        if (day.isAfter(_checkInDate!)) {
          _checkOutDate = day;
        } else {
          _checkInDate = day;
        }
      } else {
        _checkInDate = day;
        _checkOutDate = null;
      }
      _availabilityError = null;
    });

    if (_checkInDate != null && _checkOutDate != null) {
      _checkAvailability();
    }
  }

  Future<void> _checkAvailability() async {
    setState(() => _availabilityError = null);
    try {
      final activeBookings = await _bookingRepo.getActiveBookingsForHomestay(widget.homestayId);
      setState(() => _activeBookings = activeBookings);
      bool overlap = false;
      for (var b in activeBookings) {
        if (_checkInDate!.isBefore(b.checkOutDate) && _checkOutDate!.isAfter(b.checkInDate)) {
          overlap = true;
          break;
        }
      }
      if (overlap) {
        setState(() {
          _availabilityError = 'Some dates in your selection are already booked.';
          _checkOutDate = null;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _submitRequest(double totalAmount, int nights) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
      final userName = userData['name'] ?? 'Traveler';
      final userEmail = userData['email'] ?? user.email ?? '';

      final booking = HomestayBooking(
        id: '',
        homestayId: widget.homestayId,
        homestayTitle: _homestay!.title,
        hostId: _homestay!.hostId,
        travelerId: user.uid,
        travelerName: userName,
        travelerEmail: userEmail,
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        numberOfNights: nights,
        guestCount: _guestCount,
        pricePerNight: _homestay!.pricePerNight,
        accommodationAmount: _homestay!.pricePerNight * nights,
        addOnAmount: totalAmount - (_homestay!.pricePerNight * nights),
        totalAmount: totalAmount,
        selectedAddOns: _selectedAddOns,
        bookingStatus: 'pending',
      );

      await _bookingRepo.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent to host!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryDark)));
    }
    if (_homestay == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error ?? 'This homestay may have been deleted.', textAlign: TextAlign.center))),
      );
    }

    int nights = 0;
    double accommodationAmount = 0;
    if (_checkInDate != null && _checkOutDate != null) {
      nights = _checkOutDate!.difference(_checkInDate!).inDays;
      if (nights <= 0) nights = 0;
      accommodationAmount = nights * _homestay!.pricePerNight;
    }

    double addOnAmount = 0;
    for (var addon in _selectedAddOns) {
      addOnAmount += addon['price'] * addon['quantity'];
    }

    double totalAmount = accommodationAmount + addOnAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6EF),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        centerTitle: true,
        title: Text(
          'Homestay Details',
          style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : AppColors.primaryDark),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primaryDark),
            onPressed: _shareHomestay,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(nights, totalAmount),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        _buildLocationRow(),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTitle(),
                        const SizedBox(height: AppSpacing.md),
                        _buildPriceAndRatings(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTabsSection(),
                        const SizedBox(height: AppSpacing.lg),
                        if (_activeTabIndex == 0) ...[
                          _buildHostInfo(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildOverviewText(),
                          const SizedBox(height: AppSpacing.lg),
                        ] else if (_activeTabIndex == 1) ...[
                          _buildAmenitiesList(),
                          const SizedBox(height: AppSpacing.lg),
                        ] else if (_activeTabIndex == 2) ...[
                          HomestayReviewsScreen(
                            homestayId: widget.homestayId,
                            homestayTitle: _homestay!.title,
                            homestayLocation: _homestay!.location,
                            hostName: _hostData != null ? (_hostData!['name'] ?? _hostData!['fullName'] ?? 'Host') : 'Host',
                            isEmbedded: true,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        if (_activeTabIndex != 2) ...[
                          const SizedBox(height: AppSpacing.xl),
                          _buildInlineCalendar(nights),
                          const SizedBox(height: AppSpacing.xl),
                          if (_homestay!.optionalAddOns.isNotEmpty) ...[
                            _buildAddOnsSection(),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          _buildGuestsSection(),
                          const SizedBox(height: AppSpacing.xl),
                          if (nights > 0) _buildPaymentSummary(nights, accommodationAmount, addOnAmount, totalAmount),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final images = _homestay!.images;
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: AppColors.primaryDark.withValues(alpha: 0.1),
        width: double.infinity,
        child: const Icon(Icons.image, size: 64, color: AppColors.primaryDark),
      );
    }
    
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullScreenGallery(),
                child: Hero(
                  tag: 'gallery_image_$index',
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${images.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Expanded(child: Text(_homestay!.location, style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        if (_hostData?['isVerified'] == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
            child: Row(children: const [Icon(Icons.check_circle, size: 12, color: Colors.green), SizedBox(width: 4), Text('VERIFIED HOST', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))]),
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(_homestay!.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryDark, height: 1.1));
  }

  Widget _buildPriceAndRatings() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('homestay_reviews')
              .where('homestayId', isEqualTo: widget.homestayId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No reviews yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
            }
            final docs = snapshot.data!.docs;
            double total = 0;
            for (var doc in docs) {
              total += (doc.data() as Map<String, dynamic>)['rating'] ?? 0.0;
            }
            final avg = total / docs.length;
            return Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                Text(' (${docs.length} review${docs.length > 1 ? 's' : ''})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            );
          },
        ),
        if (_hostData?['isSuperhost'] == true) ...[
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('•', style: TextStyle(color: AppColors.textSecondary))),
          const Text('Superhost', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
        ],
        const Spacer(),
        Text('Rs. ${_homestay!.pricePerNight}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
        const Padding(padding: EdgeInsets.only(bottom: 2.0), child: Text(' / night', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      ],
    );
  }

  Widget _buildTabsSection() {
    final tabs = ['Overview', 'Amenities', 'Reviews'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                    _activeTabIndex = index;
                  });
                  if (tabs[index] == 'Host') {
                    _handleMessageHost();
                  } else if (tabs[index] == 'Reviews') {
                    // Just change tab, do not navigate
                  }
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        tabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isSelected)
                      Container(height: 3, width: 40, color: AppColors.primaryDark)
                    else
                      const SizedBox(height: 3),
                  ],
                ),
              ),
            );
          }),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  Future<void> _handleMessageHost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Login Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          content: const Text('You need to be logged in to send a message to the host. Would you like to log in now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
      return;
    }

    final hostId = _homestay?.hostId;
    if (hostId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Host information not available.')));
      return;
    }

    try {
      final hostDoc = await FirebaseFirestore.instance.collection('users').doc(hostId).get();
      if (!hostDoc.exists) return;
      final hostInfo = hostDoc.data()!;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TravelerHostChatScreen(
            hostId: hostId,
            hostName: hostInfo['fullName'] ?? 'Host',
            hostImage: hostInfo['profileImage'] ?? hostInfo['profileImageUrl'] ?? '',
            hostLanguages: hostInfo['languages'] != null ? (hostInfo['languages'] as List).join(' & ') : 'English',
            homestayId: _homestay?.id ?? 'unknown_id',
            homestayTitle: _homestay?.title ?? 'Homestay',
            homestayPrice: 'Rs. ${_homestay?.pricePerNight ?? 0}/night',
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }



  Widget _buildOverviewText() {
    return Text(_homestay!.description, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary));
  }

  Widget _buildAmenitiesList() {
    if (_homestay!.amenities.isEmpty) {
      return const Text('No amenities listed.', style: TextStyle(color: AppColors.textSecondary));
    }
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _homestay!.amenities.map((a) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
        child: Text(a, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }

  Widget _buildHostInfo() {
    if (_hostData == null) {
      return const Text('Host information unavailable.', style: TextStyle(color: AppColors.textSecondary));
    }
    final name = _hostData!['name'] ?? _hostData!['fullName'] ?? 'Host';
    final imageUrl = _hostData!['profileImageUrl'] as String?;
    final phone = _hostData!['phoneNumber'] as String?;
    final languages = _hostData!['languages'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('Hosted by', style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark, fontSize: 18)),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              child: imageUrl == null || imageUrl.isEmpty ? const Icon(Icons.person, size: 32, color: AppColors.primaryDark) : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
                  Text('Homestay Host • ${_homestay!.location}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (languages != null && languages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text('Speaks: ${languages.join(", ")}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  if (phone != null && phone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: GestureDetector(
                        onTap: () async {
                          final Uri url = Uri.parse('tel:$phone');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: AppColors.primaryDark),
                            const SizedBox(width: 4),
                            Text(phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: () {
            AuthGuard.requireAuth(
              context: context,
              onAuthenticated: () {
                _handleMessageHost();
              },
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: const BorderSide(color: AppColors.primaryDark),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.chat_bubble_outline, size: 18),
              SizedBox(width: 8),
              Text('Message Host', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  Widget _buildInlineCalendar(int nights) {
    int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    int firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    int prevMonthDays = DateTime(_currentMonth.year, _currentMonth.month, 0).day;
    
    // Adjust weekday to match Monday first (1: Mon, ..., 7: Sun)
    int firstDayOffset = firstWeekday - 1;

    List<Widget> dayWidgets = [];
    
    // Previous month filler
    for (int i = 0; i < firstDayOffset; i++) {
      dayWidgets.add(Center(child: Text('${prevMonthDays - firstDayOffset + i + 1}', style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14))));
    }

    // Current month days
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime day = DateTime(_currentMonth.year, _currentMonth.month, i);
      DateState state = _getDateState(day);
      
      bool isCheckIn = _checkInDate != null && _checkInDate!.year == day.year && _checkInDate!.month == day.month && _checkInDate!.day == day.day;
      bool isCheckOut = _checkOutDate != null && _checkOutDate!.year == day.year && _checkOutDate!.month == day.month && _checkOutDate!.day == day.day;
      bool isBetween = false;
      if (_checkInDate != null && _checkOutDate != null) {
        if (day.isAfter(_checkInDate!) && day.isBefore(_checkOutDate!)) isBetween = true;
      }

      Widget dayWidget;
      bool isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;

      if (isCheckIn || isCheckOut || isBetween) {
        dayWidget = Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: isCheckIn && isCheckOut ? BorderRadius.circular(20) 
                        : isCheckIn ? const BorderRadius.horizontal(left: Radius.circular(20)) 
                        : isCheckOut ? const BorderRadius.horizontal(right: Radius.circular(20)) 
                        : BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text('$i', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        );
      } else {
        Color bgColor = Colors.transparent;
        Color textColor = const Color(0xFF333333);
        BoxBorder? border;

        switch (state) {
          case DateState.past:
            textColor = const Color(0xFFE0E0E0);
            break;
          case DateState.unavailable:
            bgColor = const Color(0xFFEEEEEE);
            textColor = const Color(0xFF9E9E9E);
            break;
          case DateState.booked:
            bgColor = const Color(0xFFFFEBEE);
            textColor = const Color(0xFFD32F2F);
            break;
          case DateState.pending:
            bgColor = const Color(0xFFFFF3E0);
            textColor = const Color(0xFFF57C00);
            break;
          case DateState.available:
            if (isToday) {
              border = Border.all(color: AppColors.primaryDark, width: 1.5);
            }
            break;
        }

        dayWidget = Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            border: border,
            shape: BoxShape.circle,
          ),
          child: Text('$i', style: TextStyle(color: textColor, fontSize: 14, fontWeight: isToday || state != DateState.past ? FontWeight.w500 : FontWeight.normal)),
        );
      }

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            if (state == DateState.available) {
               _onDayTapped(day);
            }
          },
          child: dayWidget,
        )
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1)),
                child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.chevron_left, size: 20, color: AppColors.primaryDark)),
              ),
              Text(DateFormat('MMMM yyyy').format(_currentMonth), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
              GestureDetector(
                onTap: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1)),
                child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.chevron_right, size: 20, color: AppColors.primaryDark)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) => Expanded(child: Center(child: Text(day, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500))))).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: dayWidgets,
          ),
          if (_availabilityError != null)
             Padding(padding: const EdgeInsets.only(top: 8), child: Text(_availabilityError!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmoothLegend(const Color(0xFFFFFFFF), 'Available', true),
              _buildSmoothLegend(const Color(0xFFFFEBEE), 'Booked', false),
              _buildSmoothLegend(const Color(0xFFFFF3E0), 'Pending', false),
              _buildSmoothLegend(const Color(0xFFEEEEEE), 'Unavailable', false),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFBF9F6), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BOOKING DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      if (_checkInDate != null && _checkOutDate != null)
                        Text('${DateFormat('dd MMM').format(_checkInDate!)} → ${DateFormat('dd MMM').format(_checkOutDate!)} ($nights nights)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12))
                      else if (_checkInDate != null)
                        Text('${DateFormat('dd MMM').format(_checkInDate!)} → Select Checkout', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12))
                      else
                        const Text('Select Dates', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE8F6F3), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Available', style: TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmoothLegend(Color color, String label, bool isOutline) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOutline ? Colors.white : color,
            shape: BoxShape.circle,
            border: isOutline ? Border.all(color: const Color(0xFF9E9E9E), width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAddOnsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('ADD-ON VILLAGE EXPERIENCES', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark, fontSize: 14)),
                  Text('Authentic traditions hosted by the village community', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFDF7E7), borderRadius: BorderRadius.circular(8)),
              child: const Text('Recommended', style: TextStyle(color: Color(0xFF9E6541), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ..._homestay!.optionalAddOns.map((addon) {
          final isSelected = _selectedAddOns.any((a) => a['title'] == addon['title']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedAddOns.removeWhere((a) => a['title'] == addon['title']);
                } else {
                  _selectedAddOns.add({'title': addon['title'], 'price': addon['price'], 'quantity': _guestCount});
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF5FAF8) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primaryDark : AppColors.border, width: isSelected ? 1.5 : 1.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(addon['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark))),
                            Text('+Rs. ${addon['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFDF7E7), borderRadius: BorderRadius.circular(4)),
                          child: const Text('Optional', style: TextStyle(color: Color(0xFF9E6541), fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        const Text('Experience traditional village life with this custom add-on.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rs. ${addon['price']} / person', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                              child: const Row(children: [Text('Details', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)), Icon(Icons.chevron_right, size: 12, color: AppColors.textSecondary)]),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGuestsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Guests', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 16)),
              Text('Max ${_homestay!.maxGuests} guests allowed in homestay', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _guestCount > 1 ? () {
                  setState(() {
                    _guestCount--;
                    for (var a in _selectedAddOns) { a['quantity'] = _guestCount; }
                  });
                } : null,
                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)), child: const Icon(Icons.remove, size: 16, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 12),
              Text('$_guestCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _guestCount < _homestay!.maxGuests ? () {
                  setState(() {
                    _guestCount++;
                    for (var a in _selectedAddOns) { a['quantity'] = _guestCount; }
                  });
                } : null,
                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)), child: const Icon(Icons.add, size: 16, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(int nights, double accAmt, double addOnAmt, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Homestay stay (Rs. ${_homestay!.pricePerNight} x $nights nights)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('Rs. $accAmt', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
          ],
        ),
        if (_selectedAddOns.isNotEmpty) const SizedBox(height: 8),
        ..._selectedAddOns.map((addon) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('• ${addon['title']} ($_guestCount guests)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text('+Rs. ${addon['price'] * addon['quantity']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            ],
          ),
        )),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.border)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 16)),
            Text('Rs. $total', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark, fontSize: 18)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(int nights, double totalAmount) {
    bool canBook = _checkInDate != null && _checkOutDate != null && nights > 0 && _availabilityError == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nights > 0 ? 'Rs. ${NumberFormat('#,##0').format(totalAmount)}' : 'Rs. ${NumberFormat('#,##0').format(_homestay!.pricePerNight)}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark)
                  ),
                  Text(
                    nights > 0 ? 'total' : 'per night', 
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: canBook && !_isSubmitting ? () {
                  AuthGuard.requireAuth(
                    context: context,
                    onAuthenticated: () => _submitRequest(totalAmount, nights),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({super.key, required this.images, required this.initialIndex});

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: 'gallery_image_$index',
                  child: Image.network(widget.images[index], fit: BoxFit.contain),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
