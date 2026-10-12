import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../repositories/homestay_booking_repository.dart';
import '../../../../repositories/guide_booking_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../models/notification_model.dart';
import '../../../../repositories/notification_repository.dart';
import '../chat/traveler_host_chat_screen.dart';
import '../chat/traveler_chat_screen.dart';

class TravelerNotificationsScreen extends StatelessWidget {
  const TravelerNotificationsScreen({super.key});

  void _showClearAllDialog(BuildContext context, String currentUserId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Remove Notifications',
          style: AppTextStyles.screenHeading.copyWith(
            fontSize: 18,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all notifications? This cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await NotificationRepository().clearAllNotifications(currentUserId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications removed')),
                );
              }
            },
            child: const Text('Remove All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primaryDark),
          title: Text(
            'Notifications',
            style: AppTextStyles.screenHeading.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          actions: [
            if (currentUserId != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.primaryDark),
                onSelected: (value) async {
                  if (value == 'mark_read') {
                    await NotificationRepository().markAllAsRead(currentUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked all as read')),
                      );
                    }
                  } else if (value == 'clear_all') {
                    _showClearAllDialog(context, currentUserId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20, color: AppColors.primaryDark),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Remove all notifications', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorColor: const Color(0xFF1E6B52),
                labelColor: const Color(0xFF1E6B52),
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: AppTextStyles.labelLarge,
                tabs: const [
                  Tab(text: 'Booking Details'),
                  Tab(text: 'Messages'),
                  Tab(text: 'Others'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _TravelerBookingDetailsTab(),
            _TravelerMessagesTab(),
            _TravelerOthersTab(),
          ],
        ),
      ),
    );
  }
}

Widget _buildEmptyState(IconData icon, String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E6B52).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 64, color: const Color(0xFF1E6B52)),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: AppTextStyles.screenHeading.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _TravelerBookingDetailsTab extends StatelessWidget {
  const _TravelerBookingDetailsTab();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('Not logged in'));
    }

    final repo = NotificationRepository();

    return StreamBuilder<List<NotificationModel>>(
      stream: repo.getNotificationsStream(
        userId: currentUserId,
        isBooking: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return _buildEmptyState(
            Icons.event_busy,
            'No Booking Updates',
            'You have no recent booking updates.',
          );
        }

        return ListView.separated(
          itemCount: notifications.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            return _TravelerBookingNotificationItem(
              notif: notifications[index],
              repo: repo,
            );
          },
        );
      },
    );
  }
}

class _TravelerBookingNotificationItem extends StatefulWidget {
  final NotificationModel notif;
  final NotificationRepository repo;

  const _TravelerBookingNotificationItem({
    required this.notif,
    required this.repo,
  });

  @override
  State<_TravelerBookingNotificationItem> createState() =>
      _TravelerBookingNotificationItemState();
}

class _TravelerBookingNotificationItemState
    extends State<_TravelerBookingNotificationItem> {
  String? _hostName;
  String? _homestayTitle;
  String? _guideName;
  String? _packageTitle;
  bool _isGuideBooking = false;

  @override
  void initState() {
    super.initState();
    _hostName = widget.notif.hostName;
    _homestayTitle = widget.notif.homestayTitle;
    _guideName = widget.notif.guideName;
    _packageTitle = widget.notif.packageTitle;

    final meta = widget.notif.metadata;
    if (meta != null && meta['isGuideBooking'] == true) {
      _isGuideBooking = true;
    } else if (_guideName != null || _packageTitle != null) {
      _isGuideBooking = true;
    }

    _resolveBookingDetails();
  }

  Future<void> _resolveBookingDetails() async {
    final bookingId = widget.notif.relatedId;
    if (bookingId == null || bookingId.isEmpty) return;

    try {
      // 1. Try to check if it's a homestay booking
      if (!_isGuideBooking) {
        final homestayBooking =
            await HomestayBookingRepository().getBookingById(bookingId);
        if (homestayBooking != null) {
          String resolvedHost = _hostName ?? 'Host';
          try {
            final hostDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(homestayBooking.hostId)
                .get();
            if (hostDoc.exists && hostDoc.data() != null) {
              resolvedHost = hostDoc.data()!['fullName'] as String? ?? 'Host';
            }
          } catch (_) {}

          if (mounted) {
            setState(() {
              _hostName = resolvedHost;
              _homestayTitle ??= homestayBooking.homestayTitle;
              _isGuideBooking = false;
            });
          }
          return;
        }
      }

      // 2. If not a homestay booking, check guide booking
      final guideBooking =
          await GuideBookingRepository().getBooking(bookingId);
      if (guideBooking != null) {
        String resolvedGuide = _guideName ?? 'Tour Guide';
        try {
          final guideDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(guideBooking.guideId)
              .get();
          if (guideDoc.exists && guideDoc.data() != null) {
            resolvedGuide = guideDoc.data()!['fullName'] ??
                guideDoc.data()!['name'] ??
                'Tour Guide';
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _guideName = resolvedGuide;
            _packageTitle ??= guideBooking.packageTitle;
            _isGuideBooking = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notif;
    final timeStr = DateFormat('MMM d, h:mm a').format(notif.createdAt);

    IconData icon = Icons.event_available;
    Color iconColor = const Color(0xFF1E6B52);
    if (notif.title.toLowerCase().contains('approved') ||
        notif.title.toLowerCase().contains('accepted')) {
      icon = Icons.check_circle_outline;
      iconColor = const Color(0xFF1E6B52);
    } else if (notif.title.toLowerCase().contains('declined') ||
        notif.title.toLowerCase().contains('rejected')) {
      icon = Icons.cancel_outlined;
      iconColor = AppColors.error;
    } else if (notif.title.toLowerCase().contains('confirmed')) {
      icon = Icons.verified;
      iconColor = Colors.teal;
    }

    final isGuide = _isGuideBooking || _guideName != null || _packageTitle != null;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        widget.repo.deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification removed')),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            if (!notif.read)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notif.title,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: notif.read ? FontWeight.w600 : FontWeight.bold,
                  color: AppColors.primaryDark,
                  fontSize: 16,
                ),
              ),
            ),
            // Distinct category chip to clearly avoid confusion
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isGuide
                    ? const Color(0xFF1E6B52).withValues(alpha: 0.12)
                    : const Color(0xFFC47F46).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGuide ? Icons.explore_outlined : Icons.home_outlined,
                    size: 11,
                    color: isGuide
                        ? const Color(0xFF1E6B52)
                        : const Color(0xFFC47F46),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isGuide ? 'Tour Guide' : 'Homestay',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isGuide
                          ? const Color(0xFF1E6B52)
                          : const Color(0xFFC47F46),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tour Guide details
            if (isGuide) ...[
              if (_packageTitle != null && _packageTitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: Color(0xFFC47F46),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _packageTitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFC47F46),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (_guideName != null && _guideName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.person_pin_circle_outlined,
                      size: 14,
                      color: Color(0xFF1E6B52),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Guide: $_guideName',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF1E6B52),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Homestay details
              if (_homestayTitle != null && _homestayTitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 14,
                      color: Color(0xFFC47F46),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _homestayTitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFC47F46),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (_hostName != null && _hostName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Host: $_hostName',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 4),
            Text(
              notif.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: notif.read
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: notif.read ? FontWeight.normal : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeStr,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            size: 20,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            widget.repo.deleteNotification(notif.id);
          },
        ),
        onTap: () async {
          if (!notif.read) {
            await widget.repo.markAsRead(notif.id);
          }
        },
      ),
    );
  }
}

enum _MessageFilter { all, hosts, guides }

class _TravelerMessagesTab extends StatefulWidget {
  const _TravelerMessagesTab();

  @override
  State<_TravelerMessagesTab> createState() => _TravelerMessagesTabState();
}

class _TravelerMessagesTabState extends State<_TravelerMessagesTab> {
  _MessageFilter _selectedFilter = _MessageFilter.all;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Column(
      children: [
        // Filter selector bar to separate Host and Guide communications without confusion
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(
            children: [
              _buildFilterChip('All Messages', _MessageFilter.all),
              const SizedBox(width: 8),
              _buildFilterChip('Hosts', _MessageFilter.hosts, icon: Icons.home_outlined),
              const SizedBox(width: 8),
              _buildFilterChip('Tour Guides', _MessageFilter.guides, icon: Icons.explore_outlined),
            ],
          ),
        ),
        Expanded(
          child: _buildMessagesList(currentUserId),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, _MessageFilter filter, {IconData? icon}) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E6B52)
              : const Color(0xFF1E6B52).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF1E6B52),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1E6B52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(String currentUserId) {
    // If only hosts selected
    if (_selectedFilter == _MessageFilter.hosts) {
      return _buildHostChatsStream(currentUserId);
    }
    // If only guides selected
    if (_selectedFilter == _MessageFilter.guides) {
      return _buildGuideChatsStream(currentUserId);
    }

    // "All" selected: stream hostChats and chats together
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hostChats')
          .where('touristId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, hostSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('touristId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, guideSnap) {
            if (hostSnap.connectionState == ConnectionState.waiting &&
                guideSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final hostDocs = hostSnap.data?.docs ?? [];
            final guideDocs = guideSnap.data?.docs ?? [];

            final allItems = <_UnifiedChatItem>[];

            for (var doc in hostDocs) {
              final data = doc.data() as Map<String, dynamic>;
              allItems.add(_UnifiedChatItem(
                isGuide: false,
                chatDocId: doc.id,
                partnerId: data['hostId'] as String? ?? '',
                partnerName: data['hostName'] as String? ?? 'Host',
                contextTitle: data['homestayTitle'] as String? ?? 'Homestay Stay',
                lastMessage: data['lastTranslatedMessage'] as String? ??
                    data['lastMessage'] as String? ??
                    '',
                lastMessageTime: data['lastMessageTime'] as Timestamp?,
                unreadCount: data['unreadCount_$currentUserId'] as int? ?? 0,
                packageId: '',
              ));
            }

            for (var doc in guideDocs) {
              final data = doc.data() as Map<String, dynamic>;
              allItems.add(_UnifiedChatItem(
                isGuide: true,
                chatDocId: doc.id,
                partnerId: data['guideId'] as String? ?? '',
                partnerName: data['guideName'] as String? ?? 'Tour Guide',
                contextTitle: data['packageTitle'] as String? ?? 'Tour Package',
                lastMessage: data['lastTranslatedMessage'] as String? ??
                    data['lastMessage'] as String? ??
                    '',
                lastMessageTime: data['lastMessageTime'] as Timestamp?,
                unreadCount: data['unreadCount_$currentUserId'] as int? ?? 0,
                packageId: data['packageId'] as String? ?? '',
              ));
            }

            allItems.sort((a, b) {
              if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
              if (a.lastMessageTime == null) return 1;
              if (b.lastMessageTime == null) return -1;
              return b.lastMessageTime!.compareTo(a.lastMessageTime!);
            });

            if (allItems.isEmpty) {
              return _buildEmptyState(
                Icons.chat_bubble_outline,
                'No Messages Yet',
                'You have no messages from hosts or tour guides.',
              );
            }

            return ListView.separated(
              itemCount: allItems.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                return _UnifiedChatListTile(
                  item: allItems[index],
                  currentUserId: currentUserId,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHostChatsStream(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hostChats')
          .where('touristId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = dataA['lastMessageTime'] as Timestamp?;
          final timeB = dataB['lastMessageTime'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        if (docs.isEmpty) {
          return _buildEmptyState(
            Icons.home_outlined,
            'No Host Messages',
            'You have no messages from homestay hosts.',
          );
        }

        final items = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _UnifiedChatItem(
            isGuide: false,
            chatDocId: doc.id,
            partnerId: data['hostId'] as String? ?? '',
            partnerName: data['hostName'] as String? ?? 'Host',
            contextTitle: data['homestayTitle'] as String? ?? 'Homestay Stay',
            lastMessage: data['lastTranslatedMessage'] as String? ??
                data['lastMessage'] as String? ??
                '',
            lastMessageTime: data['lastMessageTime'] as Timestamp?,
            unreadCount: data['unreadCount_$currentUserId'] as int? ?? 0,
            packageId: '',
          );
        }).toList();

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            return _UnifiedChatListTile(
              item: items[index],
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }

  Widget _buildGuideChatsStream(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('touristId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = dataA['lastMessageTime'] as Timestamp?;
          final timeB = dataB['lastMessageTime'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        if (docs.isEmpty) {
          return _buildEmptyState(
            Icons.explore_outlined,
            'No Tour Guide Messages',
            'You have no messages from tour guides.',
          );
        }

        final items = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _UnifiedChatItem(
            isGuide: true,
            chatDocId: doc.id,
            partnerId: data['guideId'] as String? ?? '',
            partnerName: data['guideName'] as String? ?? 'Tour Guide',
            contextTitle: data['packageTitle'] as String? ?? 'Tour Package',
            lastMessage: data['lastTranslatedMessage'] as String? ??
                data['lastMessage'] as String? ??
                '',
            lastMessageTime: data['lastMessageTime'] as Timestamp?,
            unreadCount: data['unreadCount_$currentUserId'] as int? ?? 0,
            packageId: data['packageId'] as String? ?? '',
          );
        }).toList();

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            return _UnifiedChatListTile(
              item: items[index],
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }
}

class _UnifiedChatItem {
  final bool isGuide;
  final String chatDocId;
  final String partnerId;
  final String partnerName;
  final String contextTitle;
  final String lastMessage;
  final Timestamp? lastMessageTime;
  final int unreadCount;
  final String packageId;

  _UnifiedChatItem({
    required this.isGuide,
    required this.chatDocId,
    required this.partnerId,
    required this.partnerName,
    required this.contextTitle,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.packageId,
  });
}

class _UnifiedChatListTile extends StatelessWidget {
  final _UnifiedChatItem item;
  final String currentUserId;

  const _UnifiedChatListTile({
    required this.item,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final collectionName = item.isGuide ? 'chats' : 'hostChats';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(item.partnerId)
          .snapshots(),
      builder: (context, partnerSnapshot) {
        String partnerName = item.partnerName;
        String partnerImage = '';

        if (partnerSnapshot.hasData &&
            partnerSnapshot.data != null &&
            partnerSnapshot.data!.exists) {
          final userData =
              partnerSnapshot.data!.data() as Map<String, dynamic>;
          partnerName = userData['fullName'] ?? userData['name'] ?? partnerName;
          partnerImage = userData['profileImageUrl'] as String? ?? '';
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collectionName)
              .doc(item.chatDocId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, msgSnapshot) {
            String displayMessage = item.lastMessage;
            DateTime? displayTime = item.lastMessageTime?.toDate();
            int effectiveUnread = item.unreadCount;

            if (msgSnapshot.hasData &&
                msgSnapshot.data != null &&
                msgSnapshot.data!.docs.isNotEmpty) {
              final latestDoc = msgSnapshot.data!.docs.first;
              final latestData =
                  latestDoc.data() as Map<String, dynamic>;
              final senderId = latestData['senderId'] as String? ?? '';
              final isFromPartner = senderId != currentUserId;

              final msgText = latestData['text'] as String? ?? '';
              final msgTranslated =
                  latestData['translatedText'] as String? ?? '';

              if (isFromPartner) {
                if (msgTranslated.isNotEmpty &&
                    msgTranslated != 'Ready' &&
                    msgTranslated != 'Translation failed') {
                  displayMessage = msgTranslated;
                } else if (msgText.isNotEmpty) {
                  displayMessage = msgText;
                }
              } else {
                if (msgText.isNotEmpty) {
                  displayMessage = msgText;
                } else if (msgTranslated.isNotEmpty) {
                  displayMessage = msgTranslated;
                }
              }

              final msgTimestamp = latestData['timestamp'] as Timestamp?;
              if (msgTimestamp != null) {
                displayTime = msgTimestamp.toDate();
              }

              final isRead = latestData['read'] as bool? ?? false;
              if (isFromPartner && !isRead) {
                effectiveUnread = effectiveUnread > 0 ? effectiveUnread : 1;
              }
            }

            String timeStr = '';
            if (displayTime != null) {
              timeStr = DateFormat('MMM d, h:mm a').format(displayTime);
            }

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: partnerImage.isNotEmpty
                        ? NetworkImage(partnerImage)
                        : null,
                    backgroundColor: AppColors.border,
                    child: partnerImage.isEmpty
                        ? Icon(
                            item.isGuide ? Icons.person : Icons.person_outline,
                            color: AppColors.textSecondary,
                            size: 28,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: item.isGuide
                            ? const Color(0xFF1E6B52)
                            : const Color(0xFFC47F46),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        item.isGuide ? Icons.explore : Icons.home,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      partnerName,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isGuide
                          ? const Color(0xFF1E6B52).withValues(alpha: 0.12)
                          : const Color(0xFFC47F46).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.isGuide ? 'Tour Guide' : 'Host',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.isGuide
                            ? const Color(0xFF1E6B52)
                            : const Color(0xFFC47F46),
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    item.contextTitle,
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFFC47F46),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayMessage,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: effectiveUnread > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: effectiveUnread > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: AppTextStyles.caption.copyWith(
                        color: effectiveUnread > 0
                            ? const Color(0xFF1E6B52)
                            : AppColors.textSecondary,
                        fontWeight: effectiveUnread > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  if (effectiveUnread > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E6B52),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        effectiveUnread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: () {
                // Reset unread count for tourist
                FirebaseFirestore.instance
                    .collection(collectionName)
                    .doc(item.chatDocId)
                    .update({'unreadCount_$currentUserId': 0});

                FirebaseFirestore.instance
                    .collection(collectionName)
                    .doc(item.chatDocId)
                    .collection('messages')
                    .where('receiverId', isEqualTo: currentUserId)
                    .where('read', isEqualTo: false)
                    .get()
                    .then((snap) {
                  for (var doc in snap.docs) {
                    doc.reference.update({'read': true});
                  }
                });

                // Mark notifications for this chat as read
                FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: currentUserId)
                    .where('relatedId', isEqualTo: item.chatDocId)
                    .where('read', isEqualTo: false)
                    .get()
                    .then((snap) {
                  for (var doc in snap.docs) {
                    doc.reference.update({'read': true});
                  }
                });

                if (item.isGuide) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TravelerChatScreen(
                        chatId: item.chatDocId,
                        guideId: item.partnerId,
                        guideName: partnerName,
                        guideImage: partnerImage,
                        guideLanguages: 'English, Sinhala',
                        packageId: item.packageId,
                        packageTitle: item.contextTitle,
                        packagePrice: '',
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TravelerHostChatScreen(
                        chatId: item.chatDocId,
                        hostId: item.partnerId,
                        hostName: partnerName,
                        hostImage: partnerImage,
                        hostLanguages: 'English, Sinhala',
                        homestayId: item.chatDocId.split('_').length > 2
                            ? item.chatDocId.split('_')[2]
                            : '',
                        homestayTitle: item.contextTitle,
                        homestayPrice: '',
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _TravelerOthersTab extends StatelessWidget {
  const _TravelerOthersTab();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('Not logged in'));
    }

    final repo = NotificationRepository();

    return StreamBuilder<List<NotificationModel>>(
      stream: repo.getNotificationsStream(
        userId: currentUserId,
        isBooking: false,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allOthers = snapshot.data ?? [];
        // Filter out direct chat messages since they appear in the Messages tab
        final notifications =
            allOthers.where((n) => n.type != 'message').toList();

        if (notifications.isEmpty) {
          return _buildEmptyState(
            Icons.notifications_off_outlined,
            'All Caught Up!',
            'You have no other notifications.',
          );
        }

        return ListView.separated(
          itemCount: notifications.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            final notif = notifications[index];
            final timeStr = DateFormat('MMM d, h:mm a').format(notif.createdAt);

            IconData icon = Icons.notifications_active_outlined;
            Color iconColor = const Color(0xFF1E6B52);
            if (notif.type == 'review') {
              icon = Icons.star;
              iconColor = const Color(0xFFC47F46);
            } else if (notif.type == 'promotion') {
              icon = Icons.local_offer;
              iconColor = Colors.orange;
            }

            return Dismissible(
              key: Key(notif.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: AppColors.error,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                repo.deleteNotification(notif.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification removed')),
                );
              },
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: iconColor.withValues(alpha: 0.12),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    if (!notif.read)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  notif.title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: notif.read ? FontWeight.w600 : FontWeight.bold,
                    color: AppColors.primaryDark,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: notif.read
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: notif.read ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    repo.deleteNotification(notif.id);
                  },
                ),
                onTap: () {
                  if (!notif.read) {
                    repo.markAsRead(notif.id);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
