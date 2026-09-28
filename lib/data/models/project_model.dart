import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String category; // Flutter, Firebase, AI, UI/UX, Web, Cross-Platform
  final List<String> technologies;
  final List<String> platforms; // Android, iOS, Web, Cross-platform
  final String coverImage;
  final List<String> images;
  final List<String> videos;
  final String? projectUrl;
  final String? githubUrl;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final List<String> features;
  final String? challenge;
  final String? solution;
  final String? result;
  final bool isFeatured;
  final bool isPublished;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.category,
    required this.technologies,
    required this.platforms,
    required this.coverImage,
    this.images = const [],
    this.videos = const <String>[],
    this.projectUrl,
    this.githubUrl,
    this.appStoreUrl,
    this.playStoreUrl,
    this.features = const [],
    this.challenge,
    this.solution,
    this.result,
    this.isFeatured = false,
    this.isPublished = true,
    this.viewsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'category': category,
      'technologies': technologies,
      'platforms': platforms,
      'coverImage': coverImage,
      'images': images,
      'videos': videos,
      'projectUrl': projectUrl,
      'githubUrl': githubUrl,
      'appStoreUrl': appStoreUrl,
      'playStoreUrl': playStoreUrl,
      'features': features,
      'challenge': challenge,
      'solution': solution,
      'result': result,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
      'viewsCount': viewsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectModel(
      id: id,
      title: map['title'] as String? ?? '',
      shortDescription: map['shortDescription'] as String? ?? '',
      fullDescription: map['fullDescription'] as String? ?? '',
      category: map['category'] as String? ?? 'Flutter',
      technologies: List<String>.from(map['technologies'] ?? []),
      platforms: List<String>.from(map['platforms'] ?? []),
      coverImage: map['coverImage'] as String? ?? '',
      images: List<String>.from(map['images'] ?? []),
      videos: _readVideos(map),
      projectUrl: map['projectUrl'] as String?,
      githubUrl: map['githubUrl'] as String?,
      appStoreUrl: map['appStoreUrl'] as String?,
      playStoreUrl: map['playStoreUrl'] as String?,
      features: List<String>.from(map['features'] ?? []),
      challenge: map['challenge'] as String?,
      solution: map['solution'] as String?,
      result: map['result'] as String?,
      isFeatured: map['isFeatured'] as bool? ?? false,
      isPublished: map['isPublished'] as bool? ?? true,
      viewsCount: map['viewsCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Reads `videos`, falling back to the legacy singular `videoUrl` so
  /// documents written before the schema change still load unchanged.
  static List<String> _readVideos(Map<String, dynamic> map) {
    final videos = map['videos'];
    if (videos is List) return List<String>.from(videos);
    final legacy = map['videoUrl'];
    if (legacy is String && legacy.isNotEmpty) return <String>[legacy];
    return const <String>[];
  }
}
