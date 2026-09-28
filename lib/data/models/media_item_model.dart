import 'package:cloud_firestore/cloud_firestore.dart';

/// One indexed object of the `media` collection (spec section 14/47).
///
/// Documents are written by the `onObjectFinalized` Cloud Function with the
/// URL-encoded storage path as the document ID, so `id` round-trips back to
/// the object path with `Uri.decodeComponent`.
class MediaItemModel {
  const MediaItemModel({
    required this.id,
    required this.storagePath,
    required this.bucket,
    required this.contentType,
    required this.size,
    this.createdAt,
    this.updatedAt,
  });

  factory MediaItemModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MediaItemModel.fromMap(doc.data(), id: doc.id);
  }

  factory MediaItemModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? asDate(Object? value) =>
        value is Timestamp ? value.toDate() : null;
    return MediaItemModel(
      id: id,
      storagePath: map['storagePath'] as String? ?? '',
      bucket: map['bucket'] as String? ?? '',
      contentType: map['contentType'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      createdAt: asDate(map['createdAt']),
      updatedAt: asDate(map['updatedAt']),
    );
  }

  final String id;
  final String storagePath;
  final String bucket;
  final String contentType;
  final int size;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// File name without the `public/` folder prefix.
  String get fileName {
    final segments = storagePath.split('/').where((s) => s.isNotEmpty);
    return segments.isEmpty ? storagePath : segments.last;
  }

  bool get isImage => contentType.startsWith('image/');

  bool get isVideo => contentType.startsWith('video/');

  DateTime? get uploadedAt => updatedAt ?? createdAt;
}
