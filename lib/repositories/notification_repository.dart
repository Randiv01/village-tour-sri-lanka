import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. CREATE Notification
  Future<String> createNotification(NotificationModel notification) async {
    final docRef = await _firestore.collection('notifications').add(notification.toMap());
    return docRef.id;
  }

  // Helper method to add notification conveniently
  Future<String> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'booking', 'message', 'review', 'other'
    String? recipientRole, // 'host', 'traveler', or 'guide'
    String? relatedId,
    String? hostName,
    String? homestayTitle,
    String? guideName,
    String? packageTitle,
    Map<String, dynamic>? metadata,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      recipientRole: recipientRole,
      type: type,
      title: title,
      message: message,
      read: false,
      createdAt: DateTime.now(),
      relatedId: relatedId,
      hostName: hostName,
      homestayTitle: homestayTitle,
      guideName: guideName,
      packageTitle: packageTitle,
      metadata: metadata,
    );
    return createNotification(notification);
  }

  // 2. READ: Stream notifications for a user, optionally filtered
  Stream<List<NotificationModel>> getNotificationsStream({
    required String userId,
    String? recipientRole,
    bool? isBooking,
  }) {
    Query query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId);

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      // Filter by recipient role if provided
      if (recipientRole != null) {
        list = list.where((n) => n.recipientRole == null || n.recipientRole == recipientRole).toList();
      }

      // Filter by category if requested
      if (isBooking != null) {
        if (isBooking) {
          list = list.where((n) => n.isBooking).toList();
        } else {
          list = list.where((n) => !n.isBooking).toList();
        }
      }

      // Sort in memory by createdAt descending to avoid composite index requirement
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 3. READ: Stream unread notification count
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            final type = data['type'] as String? ?? '';
            if (type == 'message') return false;
            final isRead = data['read'] ?? data['isRead'] ?? false;
            return isRead == false;
          }).length;
        });
  }

  // 4. READ: Real-time total unread count for HOST (notifications + unread hostChats)
  Stream<int> getTotalUnreadCountForHost(String hostId) {
    late StreamController<int> controller;
    StreamSubscription? notifSub;
    StreamSubscription? chatSub;

    int notifUnread = 0;
    int chatUnread = 0;

    void update() {
      if (!controller.isClosed) {
        controller.add(notifUnread + chatUnread);
      }
    }

    controller = StreamController<int>(
      onListen: () {
        notifSub = _firestore
            .collection('notifications')
            .where('userId', isEqualTo: hostId)
            .snapshots()
            .listen((snapshot) {
          notifUnread = snapshot.docs.where((doc) {
            final data = doc.data();
            final type = data['type'] as String? ?? '';
            if (type == 'message') return false; // Already tracked by hostChats
            return (data['read'] ?? data['isRead'] ?? false) == false;
          }).length;
          update();
        }, onError: (_) {});

        chatSub = _firestore
            .collection('hostChats')
            .where('hostId', isEqualTo: hostId)
            .snapshots()
            .listen((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unread = data['unreadCount_$hostId'] as int? ?? 0;
            if (unread > 0) count += unread;
          }
          chatUnread = count;
          update();
        }, onError: (_) {});
      },
      onCancel: () {
        notifSub?.cancel();
        chatSub?.cancel();
      },
    );

    return controller.stream;
  }

  // 5. READ: Real-time total unread count for GUIDE (notifications + unread chats)
  Stream<int> getTotalUnreadCountForGuide(String guideId) {
    late StreamController<int> controller;
    StreamSubscription? notifSub;
    StreamSubscription? chatSub;

    int notifUnread = 0;
    int chatUnread = 0;

    void update() {
      if (!controller.isClosed) {
        controller.add(notifUnread + chatUnread);
      }
    }

    controller = StreamController<int>(
      onListen: () {
        notifSub = _firestore
            .collection('notifications')
            .where('userId', isEqualTo: guideId)
            .snapshots()
            .listen((snapshot) {
          notifUnread = snapshot.docs.where((doc) {
            final data = doc.data();
            final type = data['type'] as String? ?? '';
            if (type == 'message') return false; // Already tracked by chats
            return (data['read'] ?? data['isRead'] ?? false) == false;
          }).length;
          update();
        }, onError: (_) {});

        chatSub = _firestore
            .collection('chats')
            .where('guideId', isEqualTo: guideId)
            .snapshots()
            .listen((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unread = data['unreadCount_$guideId'] as int? ?? 0;
            if (unread > 0) count += unread;
          }
          chatUnread = count;
          update();
        }, onError: (_) {});
      },
      onCancel: () {
        notifSub?.cancel();
        chatSub?.cancel();
      },
    );

    return controller.stream;
  }

  // 6. READ: Real-time total unread count for TRAVELER (notifications + unread hostChats + unread guide chats)
  Stream<int> getTotalUnreadCountForTraveler(String travelerId) {
    late StreamController<int> controller;
    StreamSubscription? notifSub;
    StreamSubscription? hostChatSub;
    StreamSubscription? guideChatSub;

    int notifUnread = 0;
    int hostChatUnread = 0;
    int guideChatUnread = 0;

    void update() {
      if (!controller.isClosed) {
        controller.add(notifUnread + hostChatUnread + guideChatUnread);
      }
    }

    controller = StreamController<int>(
      onListen: () {
        notifSub = _firestore
            .collection('notifications')
            .where('userId', isEqualTo: travelerId)
            .snapshots()
            .listen((snapshot) {
          notifUnread = snapshot.docs.where((doc) {
            final data = doc.data();
            final type = data['type'] as String? ?? '';
            if (type == 'message') return false; // Already tracked by hostChats & chats
            return (data['read'] ?? data['isRead'] ?? false) == false;
          }).length;
          update();
        }, onError: (_) {});

        hostChatSub = _firestore
            .collection('hostChats')
            .where('touristId', isEqualTo: travelerId)
            .snapshots()
            .listen((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unread = data['unreadCount_$travelerId'] as int? ?? 0;
            if (unread > 0) count += unread;
          }
          hostChatUnread = count;
          update();
        }, onError: (_) {});

        guideChatSub = _firestore
            .collection('chats')
            .where('touristId', isEqualTo: travelerId)
            .snapshots()
            .listen((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unread = data['unreadCount_$travelerId'] as int? ?? 0;
            if (unread > 0) count += unread;
          }
          guideChatUnread = count;
          update();
        }, onError: (_) {});
      },
      onCancel: () {
        notifSub?.cancel();
        hostChatSub?.cancel();
        guideChatSub?.cancel();
      },
    );

    return controller.stream;
  }

  // 6. UPDATE: Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (_) {}
  }

  // 7. UPDATE: Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId, {bool? isBooking}) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? '';
        final isBookType =
            type.startsWith('booking') || type.startsWith('payment');

        if (isBooking == null ||
            (isBooking && isBookType) ||
            (!isBooking && !isBookType)) {
          batch.update(doc.reference, {'read': true});
        }
      }
      await batch.commit();

      // Reset chat unread counts for this user if clearing all or non-booking notifications
      if (isBooking == null || !isBooking) {
        try {
          final hostChatsAsHost = await _firestore
              .collection('hostChats')
              .where('hostId', isEqualTo: userId)
              .get();
          for (var doc in hostChatsAsHost.docs) {
            if ((doc.data()['unreadCount_$userId'] as int? ?? 0) > 0) {
              doc.reference.update({'unreadCount_$userId': 0});
            }
          }

          final hostChatsAsTourist = await _firestore
              .collection('hostChats')
              .where('touristId', isEqualTo: userId)
              .get();
          for (var doc in hostChatsAsTourist.docs) {
            if ((doc.data()['unreadCount_$userId'] as int? ?? 0) > 0) {
              doc.reference.update({'unreadCount_$userId': 0});
            }
          }

          final guideChatsAsGuide = await _firestore
              .collection('chats')
              .where('guideId', isEqualTo: userId)
              .get();
          for (var doc in guideChatsAsGuide.docs) {
            if ((doc.data()['unreadCount_$userId'] as int? ?? 0) > 0) {
              doc.reference.update({'unreadCount_$userId': 0});
            }
          }

          final guideChatsAsTourist = await _firestore
              .collection('chats')
              .where('touristId', isEqualTo: userId)
              .get();
          for (var doc in guideChatsAsTourist.docs) {
            if ((doc.data()['unreadCount_$userId'] as int? ?? 0) > 0) {
              doc.reference.update({'unreadCount_$userId': 0});
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  // 8. DELETE: Delete individual notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (_) {}
  }

  // 9. DELETE: Clear all notifications for user
  Future<void> clearAllNotifications(String userId, {bool? isBooking}) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? '';
        final isBookType = type.startsWith('booking');

        if (isBooking == null || (isBooking && isBookType) || (!isBooking && !isBookType)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (_) {}
  }
}
