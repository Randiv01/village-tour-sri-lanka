import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../chat/guide_chat_screen.dart';

class GuideNotificationsScreen extends StatelessWidget {
  const GuideNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark),
          ),
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
                labelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: AppTextStyles.labelLarge,
                tabs: const [
                  Tab(text: 'Booking Details'),
                  Tab(text: 'Tourist Messages'),
                  Tab(text: 'Others'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingDetailsTab(),
            _TouristMessagesTab(),
            _OthersTab(),
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
          style: AppTextStyles.screenHeading.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _BookingDetailsTab extends StatelessWidget {
  const _BookingDetailsTab();

  @override
  Widget build(BuildContext context) {
    return _buildEmptyState(
      Icons.event_busy,
      'No Booking Updates',
      'You have no recent booking updates.',
    );
  }
}

class _OthersTab extends StatelessWidget {
  const _OthersTab();

  @override
  Widget build(BuildContext context) {
    return _buildEmptyState(
      Icons.notifications_off_outlined,
      'All Caught Up!',
      'You have no other notifications.',
    );
  }
}

class _TouristMessagesTab extends StatelessWidget {
  const _TouristMessagesTab();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('guideId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var chats = snapshot.data?.docs.toList() ?? [];
        
        // Sort locally to avoid Firebase composite index requirement
        chats.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = dataA['lastMessageTime'] as Timestamp?;
          final timeB = dataB['lastMessageTime'] as Timestamp?;
          
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          
          return timeB.compareTo(timeA); // descending
        });
        if (chats.isEmpty) {
          return _buildEmptyState(
            Icons.chat_bubble_outline,
            'No Messages Yet',
            'You have no messages from tourists.',
          );
        }

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            final chatData = chats[index].data() as Map<String, dynamic>;
            final touristId = chatData['touristId'] as String? ?? '';
            final packageId = chatData['packageId'] as String? ?? '';
            final packageTitle = chatData['packageTitle'] as String? ?? 'Custom Tour';
            final lastMessage = chatData['lastTranslatedMessage'] as String? ?? chatData['lastMessage'] as String? ?? '';
            final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
            final unreadCount = chatData['unreadCount_$currentUserId'] as int? ?? 0;
            
            // We fetch the tourist info from the 'users' collection on the fly
            // because we didn't save touristName inside the chat document initially.
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(touristId).snapshots(),
              builder: (context, userSnapshot) {
                String touristName = 'Tourist';
                String touristImage = '';
                
                if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  touristName = userData['fullName'] as String? ?? 'Tourist';
                  touristImage = userData['profileImageUrl'] as String? ?? '';
                }

                String timeStr = '';
                if (lastMessageTime != null) {
                  timeStr = DateFormat('MMM d, h:mm a').format(lastMessageTime.toDate());
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: touristImage.isNotEmpty ? NetworkImage(touristImage) : null,
                    backgroundColor: AppColors.border,
                    child: touristImage.isEmpty
                        ? const Icon(Icons.person, color: AppColors.textSecondary, size: 28)
                        : null,
                  ),
                  title: Text(
                    touristName,
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
                        packageTitle,
                        style: AppTextStyles.caption.copyWith(color: const Color(0xFFC47F46), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
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
                            color: unreadCount > 0 ? const Color(0xFF1E6B52) : AppColors.textSecondary,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
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
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    // Reset unread count for guide
                    FirebaseFirestore.instance.collection('chats').doc(chats[index].id).update({
                      'unreadCount_$currentUserId': 0,
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuideChatScreen(
                          touristId: touristId,
                          touristName: touristName,
                          touristImage: touristImage,
                          touristLanguages: 'English',
                          packageId: packageId,
                          packageTitle: packageTitle,
                          packagePrice: '',
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
