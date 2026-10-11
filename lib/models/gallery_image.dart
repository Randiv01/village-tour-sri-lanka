import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryImage {
  final String id;
  final String title;
  final String description;
  final String imageUrl; // Cover / primary image URL
  final List<String> imageUrls; // List of all images in this gallery post
  final String status; // 'published' or 'draft'
  final String category;
  final String location;
  final DateTime? imageDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String uploaderId;
  final bool isCover;

  GalleryImage({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.status,
    required this.category,
    required this.location,
    this.imageDate,
    required this.createdAt,
    required this.updatedAt,
    required this.uploaderId,
    this.isCover = false,
  });

  factory GalleryImage.fromMap(Map<String, dynamic> data, String id) {
    List<String> urls = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      urls = (data['imageUrls'] as List).map((e) => e.toString()).toList();
    } else if (data['imageUrl'] != null &&
        data['imageUrl'].toString().isNotEmpty) {
      urls = [data['imageUrl'].toString()];
    }

    final String primary = data['imageUrl'] ?? (urls.isNotEmpty ? urls.first : '');
    if (urls.isEmpty && primary.isNotEmpty) {
      urls = [primary];
    }

    return GalleryImage(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: primary,
      imageUrls: urls,
      status: data['status'] ?? 'published',
      category: data['category'] ?? 'Surroundings & Views',
      location: data['location'] ?? '',
      imageDate: (data['imageDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploaderId: data['uploaderId'] ?? '',
      isCover: data['isCover'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls.isNotEmpty
          ? imageUrls
          : (imageUrl.isNotEmpty ? [imageUrl] : []),
      'status': status,
      'category': category,
      'location': location,
      'imageDate': imageDate != null ? Timestamp.fromDate(imageDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'uploaderId': uploaderId,
      'isCover': isCover,
    };
  }

  GalleryImage copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    String? status,
    String? category,
    String? location,
    DateTime? imageDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uploaderId,
    bool? isCover,
  }) {
    return GalleryImage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      category: category ?? this.category,
      location: location ?? this.location,
      imageDate: imageDate ?? this.imageDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploaderId: uploaderId ?? this.uploaderId,
      isCover: isCover ?? this.isCover,
    );
  }
}

