import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String? profileImageUrl;
  final String? country;
  final String? preferredLanguage;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    this.country,
    this.preferredLanguage,
    this.isActive = true,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      role: map['role'] ?? 'traveler',
      profileImageUrl: map['profileImageUrl'],
      country: map['country'],
      preferredLanguage: map['preferredLanguage'],
      isActive: map['isActive'] ?? true,
      isEmailVerified: map['isEmailVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'country': country,
      'preferredLanguage': preferredLanguage,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
