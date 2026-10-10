import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryImage {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String status; // 'published' or 'draft'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String uploaderId;

  GalleryImage({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.uploaderId,
  });

  factory GalleryImage.fromMap(Map<String, dynamic> data, String id) {
    return GalleryImage(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? 'draft',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploaderId: data['uploaderId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'uploaderId': uploaderId,
    };
  }
}
