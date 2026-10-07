import 'package:cloud_firestore/cloud_firestore.dart';

class TourPackage {
  static const List<String> packageCategories = [
    'Cultural & Heritage',
    'Nature & Wildlife',
    'Adventure',
    'Village Experience',
    'Food & Culinary',
    'Religious & Spiritual',
    'Family & Leisure',
    'Other Experience'
  ];

  final String id;
  final String guideId;
  final String title;
  final String description;
  final String? category;
  final String? coverImageUrl;
  final List<String> galleryImages;
  final int durationDays;
  final int nights;
  final int maxGuests;
  final double pricePerGuest;
  final String vehicleType;
  final String location;
  final List<Map<String, dynamic>> placesToVisit;
  final List<Map<String, dynamic>> activities;
  final List<Map<String, dynamic>> itinerary;
  final List<String> includedItems;
  final List<String> excludedItems;
  final String? meetingPoint;
  final String? pickupNotes;
  final List<DateTime> availabilityDates;
  final String status; // 'draft', 'active', 'inactive'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TourPackage({
    required this.id,
    required this.guideId,
    required this.title,
    required this.description,
    this.category,
    this.coverImageUrl,
    this.galleryImages = const [],
    required this.durationDays,
    required this.nights,
    required this.maxGuests,
    required this.pricePerGuest,
    required this.vehicleType,
    required this.location,
    this.placesToVisit = const [],
    this.activities = const [],
    this.itinerary = const [],
    this.includedItems = const [],
    this.excludedItems = const [],
    this.meetingPoint,
    this.pickupNotes,
    this.availabilityDates = const [],
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory TourPackage.fromMap(Map<String, dynamic> map, String documentId) {
    return TourPackage(
      id: documentId,
      guideId: map['guideId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'],
      coverImageUrl: map['coverImageUrl'] ?? map['coverImage'],
      galleryImages: List<String>.from(map['galleryImages'] ?? map['images'] ?? []),
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 1,
      nights: (map['nights'] as num?)?.toInt() ?? (map['durationNights'] as num?)?.toInt() ?? 0,
      maxGuests: (map['maxGuests'] as num?)?.toInt() ?? 1,
      pricePerGuest: (map['pricePerGuest'] as num?)?.toDouble() ?? (map['price'] as num?)?.toDouble() ?? 0.0,
      vehicleType: map['vehicleType'] ?? '',
      location: map['location'] ?? '',
      placesToVisit: _parseList(map['placesToVisit'] ?? map['places']),
      activities: _parseList(map['activities']),
      itinerary: _parseList(map['itinerary']),
      includedItems: List<String>.from(map['includedItems'] ?? []),
      excludedItems: List<String>.from(map['excludedItems'] ?? []),
      meetingPoint: map['meetingPoint'],
      pickupNotes: map['pickupNotes'],
      availabilityDates: (map['availabilityDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        } else if (e is String) {
          return {'title': e};
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'guideId': guideId,
      'title': title,
      'description': description,
      'category': category,
      'coverImageUrl': coverImageUrl,
      'galleryImages': galleryImages,
      'durationDays': durationDays,
      'nights': nights,
      'maxGuests': maxGuests,
      'pricePerGuest': pricePerGuest,
      'vehicleType': vehicleType,
      'location': location,
      'placesToVisit': placesToVisit,
      'activities': activities,
      'itinerary': itinerary,
      'includedItems': includedItems,
      'excludedItems': excludedItems,
      'meetingPoint': meetingPoint,
      'pickupNotes': pickupNotes,
      'availabilityDates': availabilityDates.map((d) => Timestamp.fromDate(d)).toList(),
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
