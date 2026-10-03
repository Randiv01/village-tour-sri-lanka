import 'package:cloud_firestore/cloud_firestore.dart';

class DestinationImage {
  final String url;
  final String publicId;

  DestinationImage({required this.url, required this.publicId});

  factory DestinationImage.fromMap(Map<String, dynamic> map) {
    return DestinationImage(
      url: map['url'] ?? '',
      publicId: map['publicId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'url': url, 'publicId': publicId};
  }
}

class Destination {
  final String id;
  final String name;
  final String shortDescription;
  final String description;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final List<DestinationImage> images;
  // Legacy fields
  final String? imageUrl;
  final String? imagePublicId;

  final bool isPopular;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  Destination({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.locationName,
    this.latitude,
    this.longitude,
    required this.images,
    this.imageUrl,
    this.imagePublicId,
    this.isPopular = false,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory Destination.fromMap(Map<String, dynamic> map, String id) {
    List<DestinationImage> parsedImages = [];

    // Parse new images array
    if (map['images'] != null && map['images'] is List) {
      parsedImages = (map['images'] as List)
          .map((i) => DestinationImage.fromMap(i as Map<String, dynamic>))
          .toList();
    }
    // Fallback for legacy single image
    else if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
      parsedImages = [
        DestinationImage(
          url: map['imageUrl'],
          publicId: map['imagePublicId'] ?? '',
        ),
      ];
    }

    return Destination(
      id: id,
      name: map['name'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      description: map['description'] ?? '',
      locationName: map['locationName'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      images: parsedImages,
      imageUrl: map['imageUrl'], // Keep reference for migrations if needed
      imagePublicId: map['imagePublicId'],
      isPopular: map['isPopular'] ?? false,
      isActive: map['isActive'] ?? true,
      displayOrder: map['displayOrder'] ?? 0,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      createdBy: map['createdBy'],
    );
  }

  static DateTime _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortDescription': shortDescription,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'images': images.map((img) => img.toMap()).toList(),
      // Backward compatibility: also save first image to legacy fields
      'imageUrl': images.isNotEmpty ? images.first.url : null,
      'imagePublicId': images.isNotEmpty ? images.first.publicId : null,
      'isPopular': isPopular,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  Destination copyWith({
    String? id,
    String? name,
    String? shortDescription,
    String? description,
    String? locationName,
    double? latitude,
    double? longitude,
    List<DestinationImage>? images,
    String? imageUrl,
    String? imagePublicId,
    bool? isPopular,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePublicId: imagePublicId ?? this.imagePublicId,
      isPopular: isPopular ?? this.isPopular,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
