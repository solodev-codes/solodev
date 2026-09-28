import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/media_compressor_service.dart';
import 'app_widgets.dart';

/// What a [MediaPickerField] is allowed to accept.
enum MediaKind { image, video }

/// Human-readable byte size, e.g. `1.4 MB`.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// A file the administrator has selected but not yet uploaded.
///
/// Exactly one of [bytes] or [url] is set:
///   * freshly picked files carry [bytes] and are uploaded when the form saves;
///   * media loaded from Firestore carries [url] and is already in Storage.
class MediaAsset {
  MediaAsset({
    required this.name,
    required this.isVideo,
    this.bytes,
    this.url,
    this.originalBytes = 0,
  }) : assert(bytes != null || url != null);

  final String name;
  final bool isVideo;
  final Uint8List? bytes;
  final String? url;

  /// Size before compression, retained so the picker can show the saving.
  final int originalBytes;

  bool get isStaged => bytes != null;
  int get currentBytes => bytes?.lengthInBytes ?? 0;
}

/// Reusable upload control covering images and video, single or multiple.
///
/// Files are compressed and staged locally on selection; nothing reaches
/// Storage until the surrounding form submits. This matches spec section 17
/// (preview, original size, compressed size) while avoiding orphaned objects
/// if the administrator cancels.
class MediaPickerField extends StatefulWidget {
  const MediaPickerField({
    super.key,
    required this.label,
    required this.kind,
    required this.assets,
    required this.onChanged,
    this.multiple = false,
    this.hint,
  });

  final String label;
  final MediaKind kind;
  final List<MediaAsset> assets;
  final ValueChanged<List<MediaAsset>> onChanged;
  final bool multiple;
  final String? hint;

  @override
  State<MediaPickerField> createState() => _MediaPickerFieldState();
}

class _MediaPickerFieldState extends State<MediaPickerField> {
  static const int _maxVideoBytes = 25 * 1024 * 1024;

  bool _busy = false;
  String? _error;

  bool get _isImage => widget.kind == MediaKind.image;

  List<String> get _extensions =>
      _isImage ? const ['jpg', 'jpeg', 'png', 'webp'] : const ['mp4', 'mov', 'webm', 'mkv'];

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _extensions,
        allowMultiple: widget.multiple,
        withData: true,
      );

      // The dialog was dismissed without a selection.
      if (result == null || result.files.isEmpty) return;

      final picked = <MediaAsset>[];
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception('${file.name} could not be read. Try again.');
        }

        if (_isImage) {
          final compressed = await MediaCompressorService.compressImageBytes(
            bytes,
            maxDimension: 1920,
            quality: 85,
          );
          picked.add(MediaAsset(
            name: file.name,
            isVideo: false,
            bytes: compressed,
            originalBytes: bytes.length,
          ));
        } else {
          // Spec section 16: no client-side video transcoding. Validate the
          // cap instead so the failure happens before any bytes are uploaded.
          if (bytes.lengthInBytes > _maxVideoBytes) {
            throw Exception(
              '${file.name} is ${formatBytes(bytes.lengthInBytes)}. '
              'The Storage limit is 25 MB - compress it first.',
            );
          }
          picked.add(MediaAsset(
            name: file.name,
            isVideo: true,
            bytes: bytes,
            originalBytes: bytes.length,
          ));
        }
      }

      final next = widget.multiple
          ? <MediaAsset>[...widget.assets, ...picked]
          : <MediaAsset>[...picked];

      if (mounted) widget.onChanged(next);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(int index) {
    final next = [...widget.assets]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (_busy)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (widget.hint != null) ...[
          const SizedBox(height: AppConstants.space4),
          Text(
            widget.hint!,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
            ),
          ),
        ],
        if (widget.assets.isNotEmpty) ...[
          const SizedBox(height: AppConstants.space12),
          Wrap(
            spacing: AppConstants.space8,
            runSpacing: AppConstants.space8,
            children: [
              for (var i = 0; i < widget.assets.length; i++)
                _AssetTile(
                  asset: widget.assets[i],
                  onRemove: () => _remove(i),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppConstants.space12),
        AppButton(
          label: _busy
              ? 'Processing...'
              : widget.assets.isEmpty
                  ? (_isImage ? 'Select image' : 'Select video')
                  : (_isImage ? 'Add more images' : 'Add more videos'),
          icon: _isImage ? Icons.image_outlined : Icons.movie_outlined,
          isSecondary: widget.assets.isNotEmpty,
          onPressed: _busy ? null : _pick,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppConstants.space8),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}

/// Preview card for a single selected or already-uploaded asset.
class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset, required this.onRemove});

  final MediaAsset asset;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 76,
              width: double.infinity,
              child: _preview(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            asset.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            _sizeLabel(),
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Remove', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sizeLabel() {
    if (asset.url != null) return 'Uploaded';
    if (asset.isVideo) return formatBytes(asset.currentBytes);
    if (asset.originalBytes <= asset.currentBytes) {
      return formatBytes(asset.currentBytes);
    }
    return '${formatBytes(asset.currentBytes)} of ${formatBytes(asset.originalBytes)}';
  }

  Widget _preview() {
    if (asset.url != null && !asset.isVideo) {
      return Image.network(
        asset.url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _FallbackIcon(Icons.broken_image),
      );
    }
    if (asset.bytes != null && !asset.isVideo) {
      return Image.memory(
        asset.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _FallbackIcon(Icons.broken_image),
      );
    }
    return const _FallbackIcon(Icons.movie_outlined);
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBackground,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.textSecondaryDark, size: 30),
    );
  }
}