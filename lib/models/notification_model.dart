import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String? recipientRole; // 'host' or 'traveler' or 'guide'
  final String type; // 'booking', 'message', 'review', 'promotion', 'system', 'other'
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String? relatedId; // bookingId, homestayId, chatId, etc.
  final String? hostName;
  final String? homestayTitle;
  final String? guideName;
  final String? packageTitle;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    this.recipientRole,
    required this.type,
    required this.title,
    required this.message,
    this.read = false,
    required this.createdAt,
    this.relatedId,
    this.hostName,
    this.homestayTitle,
    this.guideName,
    this.packageTitle,
    this.metadata,
  });

  bool get isBooking =>
      type == 'booking' ||
      type == 'booking_new' ||
      type == 'booking_update' ||
      type == 'booking_accepted' ||
      type == 'booking_rejected' ||
      type == 'booking_cancelled' ||
      type == 'payment_success' ||
      type == 'payment_failed';

  bool get isMessage => type == 'message';

  bool get isOther => !isBooking && !isMessage;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      if (recipientRole != null) 'recipientRole': recipientRole,
      'type': type,
      'title': title,
      'message': message,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      if (relatedId != null) 'relatedId': relatedId,
      if (hostName != null) 'hostName': hostName,
      if (homestayTitle != null) 'homestayTitle': homestayTitle,
      if (guideName != null) 'guideName': guideName,
      if (packageTitle != null) 'packageTitle': packageTitle,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return NotificationModel.fromMap(data, doc.id);
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['timestamp'] is Timestamp) {
      parsedDate = (map['timestamp'] as Timestamp).toDate();
    }

    final meta = map['metadata'] as Map<String, dynamic>?;

    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      recipientRole: map['recipientRole'] as String?,
      type: map['type'] as String? ?? 'other',
      title: map['title'] as String? ?? '',
      message: (map['message'] ?? map['body'] ?? '') as String,
      read: (map['read'] ?? map['isRead'] ?? false) as bool,
      createdAt: parsedDate,
      relatedId: (map['relatedId'] ?? map['bookingId'] ?? map['chatId']) as String?,
      hostName: map['hostName'] as String? ?? (meta != null ? meta['hostName'] as String? : null),
      homestayTitle: map['homestayTitle'] as String? ?? (meta != null ? meta['homestayTitle'] as String? : null),
      guideName: map['guideName'] as String? ?? (meta != null ? meta['guideName'] as String? : null),
      packageTitle: map['packageTitle'] as String? ?? (meta != null ? meta['packageTitle'] as String? : null),
      metadata: meta,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? recipientRole,
    String? type,
    String? title,
    String? message,
    bool? read,
    DateTime? createdAt,
    String? relatedId,
    String? hostName,
    String? homestayTitle,
    String? guideName,
    String? packageTitle,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientRole: recipientRole ?? this.recipientRole,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      relatedId: relatedId ?? this.relatedId,
      hostName: hostName ?? this.hostName,
      homestayTitle: homestayTitle ?? this.homestayTitle,
      guideName: guideName ?? this.guideName,
      packageTitle: packageTitle ?? this.packageTitle,
      metadata: metadata ?? this.metadata,
    );
  }
}
