import 'package:cloud_firestore/cloud_firestore.dart';

class ContactInquiry {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String country;
  final String message;
  final String status; // 'pending', 'in_progress', 'resolved', 'closed'
  final String? adminNotes;
  final String? adminReply;
  final DateTime? repliedAt;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactInquiry({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.country,
    required this.message,
    this.status = 'pending',
    this.adminNotes,
    this.adminReply,
    this.repliedAt,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactInquiry.fromMap(Map<String, dynamic> data, String id) {
    return ContactInquiry(
      id: id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString(),
      country: data['country']?.toString() ?? 'Sri Lanka',
      message: data['message']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      adminNotes: data['adminNotes']?.toString(),
      adminReply: data['adminReply']?.toString(),
      repliedAt: (data['repliedAt'] is Timestamp)
          ? (data['repliedAt'] as Timestamp).toDate()
          : null,
      userId: data['userId']?.toString(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'docType': 'contact_inquiry',
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'country': country,
      'message': message,
      'status': status,
      'adminNotes': adminNotes,
      'adminReply': adminReply,
      'repliedAt': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ContactInquiry copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? country,
    String? message,
    String? status,
    String? adminNotes,
    String? adminReply,
    DateTime? repliedAt,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactInquiry(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      message: message ?? this.message,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
