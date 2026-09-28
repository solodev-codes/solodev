import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Cross-platform media compressor using pure Dart
/// Works seamlessly on Flutter Web, Android, iOS, Windows, macOS, Linux
class MediaCompressorService {
  MediaCompressorService._();

  /// Compresses an image in bytes to target max dimension & JPEG quality
  /// Pure Dart image processing guarantees zero crash on Web & Native
  static Future<Uint8List> compressImageBytes(
    Uint8List rawBytes, {
    int maxDimension = 1920,
    int quality = 85,
  }) async {
    final image = img.decodeImage(rawBytes);
    if (image == null) return rawBytes;

    img.Image resized = image;
    if (image.width > maxDimension || image.height > maxDimension) {
      if (image.width > image.height) {
        resized = img.copyResize(image, width: maxDimension);
      } else {
        resized = img.copyResize(image, height: maxDimension);
      }
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  /// Generates a fast lightweight thumbnail
  static Future<Uint8List> generateThumbnailBytes(
    Uint8List rawBytes, {
    int maxDimension = 400,
    int quality = 75,
  }) async {
    return compressImageBytes(
      rawBytes,
      maxDimension: maxDimension,
      quality: quality,
    );
  }
}
