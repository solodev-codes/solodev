import 'package:cloud_firestore/cloud_firestore.dart';

/// A client testimonial shown in the homepage testimonial wall
/// (spec sections 9/23).
class TestimonialModel {
  const TestimonialModel({
    required this.id,
    required this.name,
    required this.role,
    required this.content,
    this.rating = 5,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TestimonialModel.fromMap(Map<String, dynamic> map, String id) {
    return TestimonialModel(
      id: id,
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      content: map['content'] as String? ?? '',
      rating: ((map['rating'] as num?) ?? 5).toInt().clamp(1, 5),
      isPublished: map['isPublished'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String role;
  final String content;
  final int rating;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'content': content,
      'rating': rating,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}