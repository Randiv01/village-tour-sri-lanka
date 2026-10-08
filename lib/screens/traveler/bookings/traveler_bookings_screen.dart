import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../models/guide_booking.dart';
import '../../../../models/homestay_booking.dart';
import '../../../../services/payment_service.dart';

class UnifiedBooking {
  final String id;
  final String type; // 'guide' or 'homestay'
  final String title;
  final String status;
  final String paymentStatus;
  final DateTime startDate;
  final DateTime endDate;
  final int guestCount;
  final double totalPrice;
  final String currency;
  final String? rejectionReason;
  final DateTime createdAt;
  final String userId;

  UnifiedBooking({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.paymentStatus,
    required this.startDate,
    required this.endDate,
    required this.guestCount,
    required this.totalPrice,
    required this.currency,
    this.rejectionReason,
    required this.createdAt,
    required this.userId,
  });
}

class TravelerBookingsScreen extends StatefulWidget {
  const TravelerBookingsScreen({super.key});

  @override
  State<TravelerBookingsScreen> createState() => _TravelerBookingsScreenState();
}

class _TravelerBookingsScreenState extends State<TravelerBookingsScreen> {
  final PaymentService _paymentService = PaymentService();
  final StreamController<List<UnifiedBooking>> _bookingsController =
      StreamController<List<UnifiedBooking>>.broadcast();
  StreamSubscription? _guideSub;
  StreamSubscription? _homestaySub;

  List<UnifiedBooking> _guideBookings = [];
  List<UnifiedBooking> _homestayBookings = [];

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'all'; // all | guide | homestay
  String _statusFilter = 'all'; // all | pending | confirmed | rejected | cancelled
  String _sortOrder = 'newest'; // newest | oldest | price_high | price_low
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _initStreams();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  void _initStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _bookingsController.add([]);
      return;
    }

    _guideSub = FirebaseFirestore.instance
        .collection('guide_bookings')
        .where('guestId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _guideBookings = snapshot.docs.map((doc) {
        final b = GuideBooking.fromMap(doc.data(), doc.id);
        return UnifiedBooking(
          id: b.id,
          type: 'guide',
          title: b.packageTitle,
          status: b.status,
          paymentStatus: b.paymentStatus,
          startDate: b.startDate,
          endDate: b.endDate,
          guestCount: b.numberOfGuests,
          totalPrice: b.totalPrice,
          currency: b.currency,
          rejectionReason: b.rejectionReason,
          createdAt: b.createdAt ?? DateTime.now(),
          userId: b.guestId,
        );
      }).toList();
      _emitCombined();
    });

    _homestaySub = FirebaseFirestore.instance
        .collection('homestay_bookings')
        .where('travelerId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _homestayBookings = snapshot.docs.map((doc) {
        final b = HomestayBooking.fromMap(doc.data(), doc.id);
        return UnifiedBooking(
          id: b.id,
          type: 'homestay',
          title: b.homestayTitle,
          status: b.bookingStatus,
          paymentStatus: b.paymentStatus,
          startDate: b.checkInDate,
          endDate: b.checkOutDate,
          guestCount: b.guestCount,
          totalPrice: b.totalAmount,
          currency: b.currency,
          rejectionReason: b.rejectionReason,
          createdAt: b.createdAt ?? DateTime.now(),
          userId: b.travelerId,
        );
      }).toList();
      _emitCombined();
    });
  }

  void _emitCombined() {
    final combined = [..._guideBookings, ..._homestayBookings];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _bookingsController.add(combined);
  }

  List<UnifiedBooking> _applyFilters(List<UnifiedBooking> all) {
    var list = all.where((b) {
      // Search query
      if (_searchQuery.isNotEmpty && !b.title.toLowerCase().contains(_searchQuery)) return false;
      // Type filter
      if (_typeFilter != 'all' && b.type != _typeFilter) return false;
      // Status filter
      if (_statusFilter != 'all' && b.status != _statusFilter) return false;
      // Date range
      if (_dateRange != null) {
        if (b.startDate.isBefore(_dateRange!.start) || b.startDate.isAfter(_dateRange!.end)) return false;
      }
      return true;
    }).toList();

    // Sort
    switch (_sortOrder) {
      case 'oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_high':
        list.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      case 'price_low':
        list.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      default: // newest
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  int get _activeFilterCount {
    int c = 0;
    if (_typeFilter != 'all') c++;
    if (_statusFilter != 'all') c++;
    if (_sortOrder != 'newest') c++;
    if (_dateRange != null) c++;
    return c;
  }

  void _clearAllFilters() {
    setState(() {
      _typeFilter = 'all';
      _statusFilter = 'all';
      _sortOrder = 'newest';
      _dateRange = null;
      _searchController.clear();
    });
  }

  void _showFilterSheet() {
    String tmpType = _typeFilter;
    String tmpStatus = _statusFilter;
    String tmpSort = _sortOrder;
    DateTimeRange? tmpDate = _dateRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    TextButton(
                      onPressed: () {
                        setLocal(() {
                          tmpType = 'all'; tmpStatus = 'all';
                          tmpSort = 'newest'; tmpDate = null;
                        });
                      },
                      child: const Text('Reset All', style: TextStyle(color: AppColors.secondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Booking Type ---
                _filterSectionTitle('Booking Type'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _filterChip('All', tmpType == 'all', () => setLocal(() => tmpType = 'all')),
                    const SizedBox(width: 8),
                    _filterChip('🏠 Homestay', tmpType == 'homestay', () => setLocal(() => tmpType = 'homestay')),
                    const SizedBox(width: 8),
                    _filterChip('🗺️ Tour Package', tmpType == 'guide', () => setLocal(() => tmpType = 'guide')),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Status ---
                _filterSectionTitle('Booking Status'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip('All', tmpStatus == 'all', () => setLocal(() => tmpStatus = 'all')),
                    _filterChip('⏳ Pending', tmpStatus == 'pending', () => setLocal(() => tmpStatus = 'pending')),
                    _filterChip('✅ Confirmed', tmpStatus == 'confirmed', () => setLocal(() => tmpStatus = 'confirmed')),
                    _filterChip('❌ Rejected', tmpStatus == 'rejected', () => setLocal(() => tmpStatus = 'rejected')),
                    _filterChip('🚫 Cancelled', tmpStatus == 'cancelled', () => setLocal(() => tmpStatus = 'cancelled')),
                    _filterChip('💳 Payment Due', tmpStatus == 'accepted', () => setLocal(() => tmpStatus = 'accepted')),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Sort By ---
                _filterSectionTitle('Sort By'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip('Newest First', tmpSort == 'newest', () => setLocal(() => tmpSort = 'newest')),
                    _filterChip('Oldest First', tmpSort == 'oldest', () => setLocal(() => tmpSort = 'oldest')),
                    _filterChip('Price: High → Low', tmpSort == 'price_high', () => setLocal(() => tmpSort = 'price_high')),
                    _filterChip('Price: Low → High', tmpSort == 'price_low', () => setLocal(() => tmpSort = 'price_low')),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Date Range ---
                _filterSectionTitle('Travel Date Range'),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2028),
                      initialDateRange: tmpDate,
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primaryDark,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setLocal(() => tmpDate = picked);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tmpDate != null ? AppColors.primaryDark : AppColors.border,
                        width: tmpDate != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined,
                            color: tmpDate != null ? AppColors.primaryDark : AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tmpDate != null
                                ? '${DateFormat('dd MMM yyyy').format(tmpDate!.start)}  →  ${DateFormat('dd MMM yyyy').format(tmpDate!.end)}'
                                : 'Select date range',
                            style: TextStyle(
                              color: tmpDate != null ? AppColors.primaryDark : AppColors.textSecondary,
                              fontWeight: tmpDate != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (tmpDate != null)
                          GestureDetector(
                            onTap: () => setLocal(() => tmpDate = null),
                            child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _typeFilter = tmpType;
                        _statusFilter = tmpStatus;
                        _sortOrder = tmpSort;
                        _dateRange = tmpDate;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary, letterSpacing: 0.5));
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primaryDark : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _guideSub?.cancel();
    _homestaySub?.cancel();
    _bookingsController.close();
    _searchController.dispose();
    super.dispose();
  }

  void _handlePayNow(UnifiedBooking booking) {
    _paymentService.processMockPayment(
      context: context,
      bookingId: booking.id,
      bookingType: booking.type == 'guide' ? 'tour_package' : 'homestay',
      userId: booking.userId,
      amount: booking.totalPrice,
      currency: booking.currency,
      description: '${booking.type == 'guide' ? 'Tour Package' : 'Homestay'}: ${booking.title}',
      onComplete: (success, transactionId) {
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful! Booking confirmed.')),
          );
        }
      },
    );
  }

  Future<void> _handleCancel(UnifiedBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this booking request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final collection = booking.type == 'guide' ? 'guide_bookings' : 'homestay_bookings';
      final statusField = booking.type == 'guide' ? 'status' : 'bookingStatus';
      await FirebaseFirestore.instance.collection(collection).doc(booking.id).update({
        statusField: 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking request cancelled.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6EF),
      appBar: AppBar(
        title: Text('My Bookings', style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark)),
        backgroundColor: const Color(0xFFF8F6EF),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<UnifiedBooking>>(
        stream: _bookingsController.stream,
        builder: (context, snapshot) {
          final allBookings = snapshot.data ?? [];
          final filtered = _applyFilters(allBookings);

          final isLoading = snapshot.connectionState == ConnectionState.waiting &&
              _guideBookings.isEmpty && _homestayBookings.isEmpty;

          return Column(
            children: [
              // Search + Filter bar
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search bookings...',
                            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _activeFilterCount > 0 ? AppColors.primaryDark : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _activeFilterCount > 0 ? AppColors.primaryDark : AppColors.border,
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _activeFilterCount > 0 ? Colors.white : AppColors.primaryDark,
                              size: 22,
                            ),
                          ),
                          if (_activeFilterCount > 0)
                            Positioned(
                              top: -5,
                              right: -5,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Active filter chips row
              if (_activeFilterCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_typeFilter != 'all') _activeChip(_typeFilter == 'guide' ? '🗺️ Tour Package' : '🏠 Homestay'),
                              if (_statusFilter != 'all') _activeChip(_statusLabel(_statusFilter)),
                              if (_sortOrder != 'newest') _activeChip(_sortLabel(_sortOrder)),
                              if (_dateRange != null) _activeChip('📅 ${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}'),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAllFilters,
                        style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Clear', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              // Results count
              if (!isLoading && allBookings.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} booking${filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
                    : filtered.isEmpty
                        ? _buildEmptyState(allBookings.isEmpty)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildBookingCard(filtered[index]),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool noBookingsAtAll) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noBookingsAtAll ? Icons.luggage_outlined : Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            noBookingsAtAll ? 'No bookings yet' : 'No results found',
            style: AppTextStyles.sectionHeading.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            noBookingsAtAll
                ? 'Your homestay and tour bookings\nwill appear here.'
                : 'Try adjusting your search\nor filters.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          if (!noBookingsAtAll) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: _clearAllFilters,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Clear Filters', style: TextStyle(color: AppColors.primaryDark)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _activeChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return '⏳ Pending';
      case 'confirmed': return '✅ Confirmed';
      case 'rejected': return '❌ Rejected';
      case 'cancelled': return '🚫 Cancelled';
      case 'accepted': return '💳 Payment Due';
      default: return s;
    }
  }

  String _sortLabel(String s) {
    switch (s) {
      case 'oldest': return '↑ Oldest';
      case 'price_high': return '💰 Price High';
      case 'price_low': return '💰 Price Low';
      default: return s;
    }
  }

  Widget _buildBookingCard(UnifiedBooking booking) {
    Color statusColor = Colors.grey;
    Color statusBgColor = Colors.grey.shade100;
    String statusText = booking.status.toUpperCase();
    bool showPayNow = false;

    if (booking.status == 'pending') {
      statusColor = Colors.orange.shade700;
      statusBgColor = Colors.orange.shade50;
      statusText = 'PENDING APPROVAL';
    } else if (booking.status == 'accepted') {
      if (booking.paymentStatus == 'unpaid' || booking.paymentStatus == 'failed') {
        statusColor = Colors.blue.shade700;
        statusBgColor = Colors.blue.shade50;
        statusText = 'PAYMENT REQUIRED';
        showPayNow = true;
      }
    } else if (booking.status == 'confirmed') {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
      statusText = 'BOOKING CONFIRMED';
    } else if (booking.status == 'rejected') {
      statusColor = Colors.red.shade700;
      statusBgColor = Colors.red.shade50;
      statusText = 'BOOKING REJECTED';
    } else if (booking.status == 'cancelled') {
      statusColor = Colors.red.shade400;
      statusBgColor = Colors.red.shade50;
      statusText = 'CANCELLED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: booking.type == 'guide'
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    booking.type == 'guide' ? '🗺️ Tour' : '🏠 Homestay',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: booking.type == 'guide' ? Colors.blue.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('dd MMM yyyy').format(booking.startDate)} → ${DateFormat('dd MMM yyyy').format(booking.endDate)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.group_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('${booking.guestCount} Guest${booking.guestCount > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  'Rs. ${NumberFormat('#,##0').format(booking.totalPrice)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
              ],
            ),

            if (booking.status == 'rejected' && booking.rejectionReason != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Reason: ${booking.rejectionReason}',
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            if (booking.status == 'pending' || showPayNow) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (booking.status == 'pending')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleCancel(booking),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (booking.status == 'pending' && showPayNow) const SizedBox(width: AppSpacing.md),
                  if (showPayNow)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handlePayNow(booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
