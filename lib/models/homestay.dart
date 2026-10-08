import 'package:cloud_firestore/cloud_firestore.dart';

class Homestay {
  final String id;
  final String hostId;
  final String title;
  final String propertyType; // 'Entire Homestay', 'Private Room', 'Shared Room'
  final String location;
  final String description;
  final double pricePerNight;
  final int rooms;
  final int maxGuests;
  final List<String> images;
  final String? coverImage;
  final List<String> amenities;
  final List<String> houseRules;
  final Map<String, bool> availableDays;
  final List<DateTime> unavailableDates;
  final String checkInTime; // '2:00 PM'
  final String checkOutTime; // '11:00 AM'
  final List<Map<String, dynamic>> optionalAddOns; // { 'title': 'Buffet Lunch', 'price': 2000 }
  final String status; // 'Active', 'Inactive'
  final bool isVerified; // true if admin verified this specific property
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Homestay({
    required this.id,
    required this.hostId,
    required this.title,
    this.propertyType = 'Entire Homestay',
    required this.location,
    required this.description,
    required this.pricePerNight,
    required this.rooms,
    required this.maxGuests,
    this.images = const [],
    this.coverImage,
    this.amenities = const [],
    this.houseRules = const [],
    this.availableDays = const {
      'monday': true,
      'tuesday': true,
      'wednesday': true,
      'thursday': true,
      'friday': true,
      'saturday': true,
      'sunday': true,
    },
    this.unavailableDates = const [],
    this.checkInTime = '2:00 PM',
    this.checkOutTime = '11:00 AM',
    this.optionalAddOns = const [],
    this.status = 'Active',
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Homestay.fromMap(Map<String, dynamic> map, String documentId) {
    Map<String, bool> parsedDays = {
      'monday': true,
      'tuesday': true,
      'wednesday': true,
      'thursday': true,
      'friday': true,
      'saturday': true,
      'sunday': true,
    };
    if (map['availableDays'] != null) {
      final m = map['availableDays'] as Map<dynamic, dynamic>;
      parsedDays = {
        'monday': m['monday'] ?? true,
        'tuesday': m['tuesday'] ?? true,
        'wednesday': m['wednesday'] ?? true,
        'thursday': m['thursday'] ?? true,
        'friday': m['friday'] ?? true,
        'saturday': m['saturday'] ?? true,
        'sunday': m['sunday'] ?? true,
      };
    }

    return Homestay(
      id: documentId,
      hostId: map['hostId'] ?? '',
      title: map['title'] ?? '',
      propertyType: map['propertyType'] ?? 'Entire Homestay',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      pricePerNight: (map['pricePerNight'] as num?)?.toDouble() ?? 0.0,
      rooms: (map['roomsCount'] as num?)?.toInt() ?? (map['rooms'] as num?)?.toInt() ?? 1,
      maxGuests: (map['maxGuests'] as num?)?.toInt() ?? 1,
      images: List<String>.from(map['images'] ?? []),
      coverImage: map['coverImage'] ?? (map['images'] != null && map['images'].isNotEmpty ? map['images'][0] : null),
      amenities: List<String>.from(map['amenities'] ?? []),
      houseRules: List<String>.from(map['houseRules'] ?? []),
      availableDays: parsedDays,
      unavailableDates: (map['unavailableDates'] as List<dynamic>?)
              ?.map((e) {
                if (e is Timestamp) return e.toDate();
                if (e is String) return DateTime.tryParse(e) ?? DateTime.now();
                return DateTime.now();
              })
              .toList() ??
          [],
      checkInTime: map['checkInTime'] ?? '2:00 PM',
      checkOutTime: map['checkOutTime'] ?? '11:00 AM',
      optionalAddOns: (map['optionalAddOns'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      status: map['status'] ?? 'Active',
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'title': title,
      'propertyType': propertyType,
      'location': location,
      'description': description,
      'pricePerNight': pricePerNight,
      'roomsCount': rooms,
      'maxGuests': maxGuests,
      'images': images,
      'coverImage': coverImage,
      'amenities': amenities,
      'houseRules': houseRules,
      'availableDays': availableDays,
      'unavailableDates': unavailableDates.map((d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}").toList(),
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'optionalAddOns': optionalAddOns,
      'status': status,
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
