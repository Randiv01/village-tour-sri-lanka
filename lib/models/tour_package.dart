import 'package:cloud_firestore/cloud_firestore.dart';

class TourPackage {
  final String id;
  final String guideId;
  final String title;
  final String description;
  final String? coverImage;
  final List<String> images;
  final int durationDays;
  final int durationNights;
  final int maxGuests;
  final String vehicleType;
  final String location;
  final double price;
  final String currency;
  final double rating;
  final int reviewCount;
  final String status;
  final List<String> itinerary;
  final List<String> includedItems;
  final List<String> excludedItems;
  final List<String> places;
  final List<String> activities;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TourPackage({
    required this.id,
    required this.guideId,
    required this.title,
    required this.description,
    this.coverImage,
    this.images = const [],
    required this.durationDays,
    required this.durationNights,
    required this.maxGuests,
    required this.vehicleType,
    required this.location,
    required this.price,
    this.currency = 'LKR',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.status = 'active',
    this.itinerary = const [],
    this.includedItems = const [],
    this.excludedItems = const [],
    this.places = const [],
    this.activities = const [],
    this.category,
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
      coverImage: map['coverImage'],
      images: List<String>.from(map['images'] ?? []),
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 1,
      durationNights: (map['durationNights'] as num?)?.toInt() ?? 0,
      maxGuests: (map['maxGuests'] as num?)?.toInt() ?? 1,
      vehicleType: map['vehicleType'] ?? '',
      location: map['location'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'LKR',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'active',
      itinerary: List<String>.from(map['itinerary'] ?? []),
      includedItems: List<String>.from(map['includedItems'] ?? []),
      excludedItems: List<String>.from(map['excludedItems'] ?? []),
      places: List<String>.from(map['places'] ?? []),
      activities: List<String>.from(map['activities'] ?? []),
      category: map['category'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guideId': guideId,
      'title': title,
      'description': description,
      'coverImage': coverImage,
      'images': images,
      'durationDays': durationDays,
      'durationNights': durationNights,
      'maxGuests': maxGuests,
      'vehicleType': vehicleType,
      'location': location,
      'price': price,
      'currency': currency,
      'rating': rating,
      'reviewCount': reviewCount,
      'status': status,
      'itinerary': itinerary,
      'includedItems': includedItems,
      'excludedItems': excludedItems,
      'places': places,
      'activities': activities,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TourPackage copyWith({
    String? id,
    String? guideId,
    String? title,
    String? description,
    String? coverImage,
    List<String>? images,
    int? durationDays,
    int? durationNights,
    int? maxGuests,
    String? vehicleType,
    String? location,
    double? price,
    String? currency,
    double? rating,
    int? reviewCount,
    String? status,
    List<String>? itinerary,
    List<String>? includedItems,
    List<String>? excludedItems,
    List<String>? places,
    List<String>? activities,
    String? category,
  }) {
    return TourPackage(
      id: id ?? this.id,
      guideId: guideId ?? this.guideId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      images: images ?? this.images,
      durationDays: durationDays ?? this.durationDays,
      durationNights: durationNights ?? this.durationNights,
      maxGuests: maxGuests ?? this.maxGuests,
      vehicleType: vehicleType ?? this.vehicleType,
      location: location ?? this.location,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      status: status ?? this.status,
      itinerary: itinerary ?? this.itinerary,
      includedItems: includedItems ?? this.includedItems,
      excludedItems: excludedItems ?? this.excludedItems,
      places: places ?? this.places,
      activities: activities ?? this.activities,
      category: category ?? this.category,
    );
  }
}
