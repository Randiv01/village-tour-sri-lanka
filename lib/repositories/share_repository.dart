import 'package:cloud_firestore/cloud_firestore.dart';

class PromoCampaign {
  final String id;
  final String sharerId;
  final String campaignTitle;
  final String homestayId;
  final String homestayTitle;
  final String homestayLocation;
  final double homestayPrice;
  final String customCaption;
  final String targetPlatform; // 'whatsapp', 'facebook', 'instagram', 'copy'
  final String status; // 'Active' or 'Paused'
  final int clicksCount;
  final DateTime createdAt;

  const PromoCampaign({
    required this.id,
    required this.sharerId,
    required this.campaignTitle,
    required this.homestayId,
    required this.homestayTitle,
    required this.homestayLocation,
    required this.homestayPrice,
    required this.customCaption,
    required this.targetPlatform,
    required this.status,
    required this.clicksCount,
    required this.createdAt,
  });

  factory PromoCampaign.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final ts = data['createdAt'] as Timestamp?;
    return PromoCampaign(
      id: doc.id,
      sharerId: data['sharerId'] as String? ?? '',
      campaignTitle: data['campaignTitle'] as String? ?? 'Untitled Campaign',
      homestayId: data['homestayId'] as String? ?? '',
      homestayTitle: data['homestayTitle'] as String? ?? 'Village Homestay',
      homestayLocation: data['homestayLocation'] as String? ?? 'Sri Lanka',
      homestayPrice: (data['homestayPrice'] as num?)?.toDouble() ?? 4500.0,
      customCaption: data['customCaption'] as String? ?? '',
      targetPlatform: data['targetPlatform'] as String? ?? 'whatsapp',
      status: data['status'] as String? ?? 'Active',
      clicksCount: (data['clicksCount'] as num?)?.toInt() ?? 0,
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }
}

class ShareAnalyticsData {
  final int totalClicks;
  final int thisWeekClicks;
  final int prevWeekClicks;
  final double weeklyGrowthPercent;
  final int totalBookings;
  final double totalEarnings;
  final Map<String, int> dailyClicks; // 'Mon', 'Tue', ... -> click count
  final Map<String, double> dailyEarnings; // 'Mon', 'Tue', ... -> LKR earned
  final Map<String, int> platformBreakdown; // 'whatsapp', 'facebook', 'instagram', 'copy', 'other'
  final List<Map<String, dynamic>> sharedHomestays; // summary per homestay

  const ShareAnalyticsData({
    required this.totalClicks,
    required this.thisWeekClicks,
    required this.prevWeekClicks,
    required this.weeklyGrowthPercent,
    required this.totalBookings,
    required this.totalEarnings,
    required this.dailyClicks,
    required this.dailyEarnings,
    required this.platformBreakdown,
    required this.sharedHomestays,
  });
}

class ShareRepository {
  final FirebaseFirestore _db;

  /// Reward earned per valid referral click/share (LKR)
  static const double rewardPerClickLkr = 150.0;

  /// Bonus commission rate on bookings of shared homestays (5%)
  static const double bookingCommissionRate = 0.05;

  ShareRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// CREATE: Create a new custom promotional campaign in Firestore.
  Future<String> createCampaign({
    required String sharerId,
    required String campaignTitle,
    required String homestayId,
    required String homestayTitle,
    required String homestayLocation,
    required double homestayPrice,
    required String customCaption,
    required String targetPlatform,
    String status = 'Active',
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    final docRef = await _db.collection('test_users').add({
      'docType': 'promo_campaign',
      'sharerId': sharerId,
      'campaignTitle': campaignTitle.trim(),
      'homestayId': homestayId,
      'homestayTitle': homestayTitle,
      'homestayLocation': homestayLocation,
      'homestayPrice': homestayPrice,
      'customCaption': customCaption.trim(),
      'targetPlatform': targetPlatform,
      'status': status,
      'clicksCount': 0,
      'createdAt': now,
      'updatedAt': now,
    });
    return docRef.id;
  }

  /// UPDATE: Update an existing promotional campaign in Firestore.
  Future<void> updateCampaign({
    required String campaignId,
    required String campaignTitle,
    required String homestayId,
    required String homestayTitle,
    required String homestayLocation,
    required double homestayPrice,
    required String customCaption,
    required String targetPlatform,
    required String status,
  }) async {
    await _db.collection('test_users').doc(campaignId).update({
      'campaignTitle': campaignTitle.trim(),
      'homestayId': homestayId,
      'homestayTitle': homestayTitle,
      'homestayLocation': homestayLocation,
      'homestayPrice': homestayPrice,
      'customCaption': customCaption.trim(),
      'targetPlatform': targetPlatform,
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// DELETE: Delete a promotional campaign from Firestore.
  Future<void> deleteCampaign(String campaignId) async {
    await _db.collection('test_users').doc(campaignId).delete();
  }

  /// READ helper: Extract sorted [PromoCampaign] items from the user's `test_users` stream.
  static List<PromoCampaign> extractCampaigns(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final campaigns = docs
        .where((d) => d.data()['docType'] == 'promo_campaign')
        .map((d) => PromoCampaign.fromDoc(d))
        .toList();
    campaigns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return campaigns;
  }

  /// Track that [sharerId] shared [homestayId] via [platform], or a shared link was clicked.
  /// Platform values: 'whatsapp', 'facebook', 'instagram', 'copy', 'other'
  Future<void> trackShareClick({
    required String sharerId,
    required String homestayId,
    required String homestayTitle,
    String homestayLocation = '',
    required String platform,
    String? campaignId,
  }) async {
    final now = DateTime.now();
    final dayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Add individual click/share event document in `test_users`
    // (which has open read/write permissions in deployed Firestore rules)
    await _db.collection('test_users').add({
      'docType': 'share_click',
      'sharerId': sharerId,
      'homestayId': homestayId,
      'homestayTitle': homestayTitle,
      'homestayLocation': homestayLocation,
      'platform': platform,
      'campaignId': ?campaignId,
      'clickedAt': Timestamp.fromDate(now),
      'dayKey': dayKey,
      'rewardEarned': rewardPerClickLkr,
      'referralTag': '${sharerId}_$homestayId',
    });

    // 2. If shared from a specific campaign, increment its click count
    if (campaignId != null && campaignId.isNotEmpty) {
      try {
        await _db.collection('test_users').doc(campaignId).update({
          'clicksCount': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(now),
        });
      } catch (_) {}
    }

    // 3. Best-effort update of user's promoter stats
    try {
      final userRef = _db.collection('users').doc(sharerId);
      await userRef.update({
        'promoter_totalClicks': FieldValue.increment(1),
        'promoter_totalEarnings': FieldValue.increment(rewardPerClickLkr),
        'promoter_platformBreakdown.$platform': FieldValue.increment(1),
        'promoter_lastShareAt': Timestamp.fromDate(now),
      });
    } catch (_) {}
  }

  /// Stream all click & campaign documents for [uid] without requiring composite indexes.
  Stream<QuerySnapshot<Map<String, dynamic>>> getClicksStream(String uid) {
    return _db
        .collection('test_users')
        .where('sharerId', isEqualTo: uid)
        .snapshots();
  }

  /// Compute full [ShareAnalyticsData] from click documents and bookings.
  static ShareAnalyticsData computeAnalytics({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> clickDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> bookingDocs,
    required String uid,
    String periodFilter = 'This Month', // 'This Week', 'This Month', 'All Time'
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));
    final fourteenDaysAgo = todayStart.subtract(const Duration(days: 13));
    final monthStart = DateTime(now.year, now.month, 1);

    int filteredClicks = 0;
    int thisWeekClicks = 0;
    int prevWeekClicks = 0;

    final Map<String, int> platformBreakdown = {
      'whatsapp': 0,
      'instagram': 0,
      'facebook': 0,
      'copy': 0,
      'other': 0,
    };

    // Initialize last 7 days map in chronological order
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, int> dailyClicksByDate = {};
    final Map<String, String> dateToDayLabel = {};

    for (int i = 6; i >= 0; i--) {
      final d = todayStart.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dailyClicksByDate[key] = 0;
      dateToDayLabel[key] = weekdayNames[d.weekday - 1];
    }

    final Map<String, Map<String, dynamic>> homestayMap = {};

    for (final doc in clickDocs) {
      final data = doc.data();
      // Skip promo_campaign metadata docs when counting click events
      if (data['docType'] == 'promo_campaign') continue;

      final ts = data['clickedAt'] as Timestamp?;
      final clickedAt = ts?.toDate() ?? now;
      final platform = (data['platform'] as String? ?? 'other').toLowerCase();
      final homestayId = data['homestayId'] as String? ?? '';
      final homestayTitle = data['homestayTitle'] as String? ?? 'Village Homestay';
      final homestayLocation = data['homestayLocation'] as String? ?? '';

      // Period filter check
      bool includeInPeriod = true;
      if (periodFilter == 'This Week') {
        includeInPeriod = !clickedAt.isBefore(sevenDaysAgo);
      } else if (periodFilter == 'This Month') {
        includeInPeriod = !clickedAt.isBefore(monthStart);
      }

      if (includeInPeriod) {
        filteredClicks++;
        platformBreakdown[platform] = (platformBreakdown[platform] ?? 0) + 1;

        if (homestayId.isNotEmpty) {
          final existing = homestayMap[homestayId];
          if (existing == null) {
            homestayMap[homestayId] = {
              'homestayId': homestayId,
              'homestayTitle': homestayTitle,
              'homestayLocation': homestayLocation,
              'clicks': 1,
              'lastClickedAt': clickedAt,
            };
          } else {
            existing['clicks'] = (existing['clicks'] as int) + 1;
            if (clickedAt.isAfter(existing['lastClickedAt'] as DateTime)) {
              existing['lastClickedAt'] = clickedAt;
            }
          }
        }
      }

      // Weekly comparison
      if (!clickedAt.isBefore(sevenDaysAgo)) {
        thisWeekClicks++;
        final dKey =
            '${clickedAt.year}-${clickedAt.month.toString().padLeft(2, '0')}-${clickedAt.day.toString().padLeft(2, '0')}';
        if (dailyClicksByDate.containsKey(dKey)) {
          dailyClicksByDate[dKey] = dailyClicksByDate[dKey]! + 1;
        }
      } else if (!clickedAt.isBefore(fourteenDaysAgo) &&
          clickedAt.isBefore(sevenDaysAgo)) {
        prevWeekClicks++;
      }
    }

    double weeklyGrowthPercent = 0.0;
    if (prevWeekClicks == 0) {
      weeklyGrowthPercent = thisWeekClicks > 0 ? 100.0 : 0.0;
    } else {
      weeklyGrowthPercent =
          ((thisWeekClicks - prevWeekClicks) / prevWeekClicks) * 100.0;
    }

    // Build ordered dailyClicks and dailyEarnings maps
    final Map<String, int> orderedDailyClicks = {};
    final Map<String, double> orderedDailyEarnings = {};
    dailyClicksByDate.forEach((dateKey, dayCount) {
      final label = dateToDayLabel[dateKey]!;
      orderedDailyClicks[label] = dayCount;
      orderedDailyEarnings[label] = dayCount * rewardPerClickLkr;
    });

    // Calculate bookings & commission from shared homestays or user bookings
    final sharedIds = homestayMap.keys.toSet();
    int matchedBookings = 0;
    double bookingCommission = 0.0;

    for (final bDoc in bookingDocs) {
      final bData = bDoc.data();
      final status = (bData['bookingStatus'] as String? ?? 'pending').toLowerCase();
      if (status == 'cancelled' || status == 'rejected') continue;

      final bHomestayId = bData['homestayId'] as String? ?? '';
      final bReferredBy = bData['referredBy'] as String? ?? '';
      final bTravelerId = bData['travelerId'] as String? ?? '';
      final bHostId = bData['hostId'] as String? ?? '';

      if (bReferredBy == uid ||
          sharedIds.contains(bHomestayId) ||
          bTravelerId == uid ||
          bHostId == uid) {
        matchedBookings++;
        final totalAmt = (bData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        bookingCommission += totalAmt * bookingCommissionRate;
      }
    }

    final totalEarnings =
        (filteredClicks * rewardPerClickLkr) + bookingCommission;

    final sharedList = homestayMap.values.toList()
      ..sort((a, b) => (b['clicks'] as int).compareTo(a['clicks'] as int));

    return ShareAnalyticsData(
      totalClicks: filteredClicks,
      thisWeekClicks: thisWeekClicks,
      prevWeekClicks: prevWeekClicks,
      weeklyGrowthPercent: weeklyGrowthPercent,
      totalBookings: matchedBookings,
      totalEarnings: totalEarnings,
      dailyClicks: orderedDailyClicks,
      dailyEarnings: orderedDailyEarnings,
      platformBreakdown: platformBreakdown,
      sharedHomestays: sharedList,
    );
  }
}
