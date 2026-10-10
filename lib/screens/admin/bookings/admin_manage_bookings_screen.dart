import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../models/homestay_booking.dart';
import '../../../models/guide_booking.dart';

class AdminManageBookingsScreen extends StatelessWidget {
  const AdminManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              'All Bookings',
              style: AppTextStyles.screenHeading.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Homestays'),
              Tab(text: 'Tour Packages'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HomestayBookingsTab(),
            _PackageBookingsTab(),
          ],
        ),
      ),
    );
  }
}

class _HomestayBookingsTab extends StatefulWidget {
  const _HomestayBookingsTab();

  @override
  State<_HomestayBookingsTab> createState() => _HomestayBookingsTabState();
}

class _HomestayBookingsTabState extends State<_HomestayBookingsTab> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Accepted',
    'Confirmed',
    'Rejected',
    'Cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('homestay_bookings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No homestay bookings found.'));
              }

              final docs = snapshot.data!.docs;
              
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final booking = HomestayBooking.fromMap(data, doc.id);
                
                // Status Filter
                if (_statusFilter != 'All' && 
                    booking.bookingStatus.toLowerCase() != _statusFilter.toLowerCase()) {
                  return false;
                }
                
                // Search Query
                if (_searchQuery.isNotEmpty) {
                  final searchLower = _searchQuery.toLowerCase();
                  final idMatch = booking.id.toLowerCase().contains(searchLower);
                  final nameMatch = booking.travelerName.toLowerCase().contains(searchLower);
                  final titleMatch = booking.homestayTitle.toLowerCase().contains(searchLower);
                  if (!idMatch && !nameMatch && !titleMatch) {
                    return false;
                  }
                }
                
                return true;
              }).toList();

              if (filteredDocs.isEmpty) {
                 return const Center(child: Text('No bookings match your search.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final booking = HomestayBooking.fromMap(data, doc.id);
                  return _buildHomestayBookingCard(booking);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by ID, Name or Title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                icon: const Icon(Icons.filter_list, color: AppColors.primary),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _statusFilter = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomestayBookingCard(HomestayBooking booking) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.homestayTitle,
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${booking.currency} ${currencyFormat.format(booking.totalAmount)}',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${booking.id.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Traveler: ${booking.travelerName}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Dates: ${DateFormat('MMM d, y').format(booking.checkInDate)} - ${DateFormat('MMM d, y').format(booking.checkOutDate)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Nights: ${booking.numberOfNights} | Guests: ${booking.guestCount}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(booking.bookingStatus, isPayment: false),
                _buildStatusBadge(booking.paymentStatus, isPayment: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {required bool isPayment}) {
    Color color = Colors.grey;
    if (status == 'confirmed' || status == 'paid' || status == 'accepted') {
      color = Colors.green;
    } else if (status == 'pending' || status == 'unpaid') {
      color = Colors.orange;
    } else if (status == 'rejected' || status == 'cancelled' || status == 'failed') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${isPayment ? 'Payment: ' : ''}${status.toUpperCase()}',
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PackageBookingsTab extends StatefulWidget {
  const _PackageBookingsTab();

  @override
  State<_PackageBookingsTab> createState() => _PackageBookingsTabState();
}

class _PackageBookingsTabState extends State<_PackageBookingsTab> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Rejected',
    'Cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('guide_bookings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No package bookings found.'));
              }

              final docs = snapshot.data!.docs;
              
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final booking = GuideBooking.fromMap(data, doc.id);
                
                // Status Filter
                if (_statusFilter != 'All' && 
                    booking.status.toLowerCase() != _statusFilter.toLowerCase()) {
                  return false;
                }
                
                // Search Query
                if (_searchQuery.isNotEmpty) {
                  final searchLower = _searchQuery.toLowerCase();
                  final idMatch = booking.id.toLowerCase().contains(searchLower);
                  final nameMatch = booking.guestName.toLowerCase().contains(searchLower);
                  final titleMatch = booking.packageTitle.toLowerCase().contains(searchLower);
                  if (!idMatch && !nameMatch && !titleMatch) {
                    return false;
                  }
                }
                
                return true;
              }).toList();

              if (filteredDocs.isEmpty) {
                 return const Center(child: Text('No bookings match your search.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final booking = GuideBooking.fromMap(data, doc.id);
                  return _buildPackageBookingCard(booking);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by ID, Name or Title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                icon: const Icon(Icons.filter_list, color: AppColors.primary),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _statusFilter = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageBookingCard(GuideBooking booking) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.packageTitle,
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${booking.currency} ${currencyFormat.format(booking.totalPrice)}',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${booking.id.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Guest: ${booking.guestName}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Dates: ${DateFormat('MMM d, y').format(booking.startDate)} - ${DateFormat('MMM d, y').format(booking.endDate)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Guests: ${booking.numberOfGuests}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(booking.status, isPayment: false),
                _buildStatusBadge(booking.paymentStatus, isPayment: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {required bool isPayment}) {
    Color color = Colors.grey;
    if (status == 'confirmed' || status == 'paid' || status == 'completed') {
      color = Colors.green;
    } else if (status == 'pending' || status == 'unpaid') {
      color = Colors.orange;
    } else if (status == 'rejected' || status == 'cancelled' || status == 'failed') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${isPayment ? 'Payment: ' : ''}${status.toUpperCase()}',
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
