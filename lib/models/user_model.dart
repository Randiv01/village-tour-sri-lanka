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
  final List<String>? languages;
  final String? specialization;
  final String? bio;
  final List<String> favorites;
  final List<String> favoriteDestinations;
  final bool isActive;
  final bool isEmailVerified;
  final bool isVerified;
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
    this.languages,
    this.specialization,
    this.bio,
    this.favorites = const [],
    this.favoriteDestinations = const [],
    this.isActive = true,
    this.isEmailVerified = false,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  String get location => (country != null && country!.isNotEmpty) ? country! : '';

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    List<String>? parsedLanguages;
    if (map['languages'] is List) {
      parsedLanguages = (map['languages'] as List).map((e) => e.toString()).toList();
    } else if (map['languages'] is String && (map['languages'] as String).isNotEmpty) {
      parsedLanguages = (map['languages'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      role: map['role'] ?? 'traveler',
      profileImageUrl: map['profileImageUrl'] ?? map['profileImage'],
      country: map['country'] ?? map['location'],
      preferredLanguage: map['preferredLanguage'],
      languages: parsedLanguages,
      specialization: map['specialization'] ?? map['guideType'],
      bio: map['bio'] ?? map['description'],
      favorites: List<String>.from(map['favorites'] ?? []),
      favoriteDestinations: List<String>.from(map['favoriteDestinations'] ?? []),
      isActive: map['isActive'] ?? true,
      isEmailVerified: map['isEmailVerified'] ?? false,
      isVerified: map['isVerified'] ?? map['verified'] ?? false,
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
      if (languages != null) 'languages': languages,
      if (specialization != null) 'specialization': specialization,
      if (bio != null) 'bio': bio,
      if (favorites.isNotEmpty) 'favorites': favorites,
      if (favoriteDestinations.isNotEmpty) 'favoriteDestinations': favoriteDestinations,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'isVerified': isVerified,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
