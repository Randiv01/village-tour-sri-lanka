import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../models/notification_model.dart';
import '../../../../repositories/notification_repository.dart';
import '../chat/traveler_host_chat_screen.dart';

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
                  Tab(text: 'Host Messages'),
                  Tab(text: 'Others'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _TravelerBookingDetailsTab(),
            _TravelerHostMessagesTab(),
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
            final notif = notifications[index];
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
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
                  onPressed: () {
                    repo.deleteNotification(notif.id);
                  },
                ),
                onTap: () async {
                  if (!notif.read) {
                    await repo.markAsRead(notif.id);
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

class _TravelerHostMessagesTab extends StatelessWidget {
  const _TravelerHostMessagesTab();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hostChats')
          .where('touristId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var chats = snapshot.data?.docs.toList() ?? [];

        // Sort locally by lastMessageTime descending
        chats.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = dataA['lastMessageTime'] as Timestamp?;
          final timeB = dataB['lastMessageTime'] as Timestamp?;

          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;

          return timeB.compareTo(timeA);
        });

        if (chats.isEmpty) {
          return _buildEmptyState(
            Icons.chat_bubble_outline,
            'No Messages Yet',
            'You have no messages from hosts.',
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            final chatDoc = chats[index];
            final chatData = chatDoc.data() as Map<String, dynamic>;
            final hostId = chatData['hostId'] as String? ?? '';
            final homestayId = chatData['homestayId'] as String? ?? '';
            final homestayTitle =
                chatData['homestayTitle'] as String? ?? 'Homestay Stay';
            final lastMessage =
                chatData['lastMessage'] as String? ?? '';
            final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
            final unreadCount =
                chatData['unreadCount_$currentUserId'] as int? ?? 0;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(hostId)
                  .snapshots(),
              builder: (context, hostSnapshot) {
                String hostName = chatData['hostName'] as String? ?? 'Host';
                String hostImage = '';

                if (hostSnapshot.hasData &&
                    hostSnapshot.data != null &&
                    hostSnapshot.data!.exists) {
                  final userData =
                      hostSnapshot.data!.data() as Map<String, dynamic>;
                  hostName = userData['fullName'] as String? ?? hostName;
                  hostImage = userData['profileImageUrl'] as String? ?? '';
                }

                String timeStr = '';
                if (lastMessageTime != null) {
                  timeStr = DateFormat('MMM d, h:mm a')
                      .format(lastMessageTime.toDate());
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: hostImage.isNotEmpty
                        ? NetworkImage(hostImage)
                        : null,
                    backgroundColor: AppColors.border,
                    child: hostImage.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 28,
                          )
                        : null,
                  ),
                  title: Text(
                    hostName,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        homestayTitle,
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFC47F46),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: unreadCount > 0
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: unreadCount > 0
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
                            color: unreadCount > 0
                                ? const Color(0xFF1E6B52)
                                : AppColors.textSecondary,
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      if (unreadCount > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E6B52),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
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
                        .collection('hostChats')
                        .doc(chatDoc.id)
                        .update({'unreadCount_$currentUserId': 0});

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TravelerHostChatScreen(
                          hostId: hostId,
                          hostName: hostName,
                          hostImage: hostImage,
                          hostLanguages: 'English, Sinhala',
                          homestayId: homestayId,
                          homestayTitle: homestayTitle,
                          homestayPrice: '',
                        ),
                      ),
                    );
                  },
                );
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

        final notifications = snapshot.data ?? [];
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
                      backgroundColor: const Color(0xFF1E6B52).withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF1E6B52),
                        size: 24,
                      ),
                    ),
                    if (!notif.read)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E6B52),
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
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
                  onPressed: () {
                    repo.deleteNotification(notif.id);
                  },
                ),
                onTap: () async {
                  if (!notif.read) {
                    await repo.markAsRead(notif.id);
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
