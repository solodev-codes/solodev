import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String iconName;
  final String coverImage;
  final List<String> technologies;
  final List<String> features;
  final List<String> process;
  final List<String> benefits;
  final bool isPublished;
  final bool isFeatured;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.iconName,
    required this.coverImage,
    this.technologies = const [],
    this.features = const [],
    this.process = const [],
    this.benefits = const [],
    this.isPublished = true,
    this.isFeatured = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'iconName': iconName,
      'coverImage': coverImage,
      'technologies': technologies,
      'features': features,
      'process': process,
      'benefits': benefits,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      title: map['title'] as String? ?? '',
      shortDescription: map['shortDescription'] as String? ?? '',
      fullDescription: map['fullDescription'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'code',
      coverImage: map['coverImage'] as String? ?? '',
      technologies: List<String>.from(map['technologies'] ?? []),
      features: List<String>.from(map['features'] ?? []),
      process: List<String>.from(map['process'] ?? []),
      benefits: List<String>.from(map['benefits'] ?? []),
      isPublished: map['isPublished'] as bool? ?? true,
      isFeatured: map['isFeatured'] as bool? ?? false,
      sortOrder: map['sortOrder'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
