import 'package:cloud_firestore/cloud_firestore.dart';

class Destination {
  final String id;
  final String name;
  final String shortDescription;
  final String description;
  final String locationName;
  final double? latitude;
  final double? longitude;
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
    return Destination(
      id: id,
      name: map['name'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      description: map['description'] ?? '',
      locationName: map['locationName'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'],
      imagePublicId: map['imagePublicId'],
      isPopular: map['isPopular'] ?? false,
      isActive: map['isActive'] ?? true,
      displayOrder: map['displayOrder'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortDescription': shortDescription,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
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
