import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryImage {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String status; // 'published' or 'draft'
  final String category;
  final String location;
  final DateTime? imageDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String uploaderId;

  GalleryImage({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.category,
    required this.location,
    this.imageDate,
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
      status: data['status'] ?? 'published',
      category: data['category'] ?? 'Surroundings & Views',
      location: data['location'] ?? '',
      imageDate: (data['imageDate'] as Timestamp?)?.toDate(),
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
      'category': category,
      'location': location,
      'imageDate': imageDate != null ? Timestamp.fromDate(imageDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'uploaderId': uploaderId,
    };
  }
}
