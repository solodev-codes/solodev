import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/media_picker.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/portfolio_repository.dart';

/// Platforms a project can be distributed on.
const List<String> kProjectPlatforms = <String>[
  'Android',
  'iOS',
  'Web',
  'Windows',
  'macOS',
  'Linux',
];

/// Creates a new project, or edits an existing one when [projectId] is supplied.
///
/// Media is selected through [MediaPickerField]: files are compressed and
/// staged locally when picked, then uploaded to Storage only when the form is
/// saved. Nothing here accepts a raw image URL, and no cover art, platform or
/// timestamp is ever fabricated.
class ProjectEditorScreen extends ConsumerStatefulWidget {
  const ProjectEditorScreen({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<ProjectEditorScreen> createState() =>
      _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends ConsumerState<ProjectEditorScreen> {
  static const Uuid _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _category = TextEditingController();
  final _shortDesc = TextEditingController();
  final _fullDesc = TextEditingController();
  final _techs = TextEditingController();
  final _features = TextEditingController();
  final _projectUrl = TextEditingController();
  final _githubUrl = TextEditingController();
  final _appStoreUrl = TextEditingController();
  final _playStoreUrl = TextEditingController();
  final _challenge = TextEditingController();
  final _solution = TextEditingController();
  final _result = TextEditingController();

  final Set<String> _platforms = <String>{'Android', 'iOS', 'Web'};

  MediaAsset? _coverAsset;
  List<MediaAsset> _imageAssets = <MediaAsset>[];
  List<MediaAsset> _videoAssets = <MediaAsset>[];

  bool _isPublished = false;
  bool _isFeatured = false;
  bool _saving = false;
  bool _loading = false;
  String? _error;
  String? _progressLabel;
  double _uploadProgress = 0;

  int _viewsCount = 0;
  DateTime? _createdAt;

  bool get _isEditing => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _shortDesc.dispose();
    _fullDesc.dispose();
    _techs.dispose();
    _features.dispose();
    _projectUrl.dispose();
    _githubUrl.dispose();
    _appStoreUrl.dispose();
    _playStoreUrl.dispose();
    _challenge.dispose();
    _solution.dispose();
    _result.dispose();
    super.dispose();
  }

  /// Builds a Storage path for this project (spec section 38).
  String _storagePath(String folder, String name) =>
      'portfolio/projects/$_projectId/$folder/$name';

  String _newId = '';
  String get _projectId => widget.projectId ?? _newId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_newId.isEmpty) _newId = _uuid.v4();
  }

  String? _trimOrNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  List<String> _splitCommas(String value) => value
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  List<String> _splitLines(String value) => value
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  String _extensionOf(String name, String fallback) {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return fallback;
    return name.substring(i + 1).toLowerCase();
  }

  String _videoContentType(String ext) {
    switch (ext) {
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'video/mp4';
    }
  }

  /// Derives a readable label from a previously uploaded URL.
  String _labelFromUrl(String url) {
    final segment = Uri.tryParse(url)?.pathSegments.isNotEmpty ?? false
        ? Uri.parse(url).pathSegments.last
        : '';
    return segment.isEmpty ? 'Media' : Uri.decodeComponent(segment);
  }

  Future<void> _loadExisting() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final projects = await ref.read(allProjectsProvider.future);
      final matches = projects.where((p) => p.id == widget.projectId).toList();
      if (matches.isEmpty) {
        if (mounted) setState(() => _error = 'That project no longer exists.');
        return;
      }
      final existing = matches.first;
      if (!mounted) return;
      setState(() {
        _title.text = existing.title;
        _category.text = existing.category;
        _shortDesc.text = existing.shortDescription;
        _fullDesc.text = existing.fullDescription;
        _techs.text = existing.technologies.join(', ');
        _features.text = existing.features.join('\n');
        _projectUrl.text = existing.projectUrl ?? '';
        _githubUrl.text = existing.githubUrl ?? '';
        _appStoreUrl.text = existing.appStoreUrl ?? '';
        _playStoreUrl.text = existing.playStoreUrl ?? '';
        _challenge.text = existing.challenge ?? '';
        _solution.text = existing.solution ?? '';
        _result.text = existing.result ?? '';
        _platforms
          ..clear()
          ..addAll(existing.platforms);
        _isPublished = existing.isPublished;
        _isFeatured = existing.isFeatured;
        _viewsCount = existing.viewsCount;
        _createdAt = existing.createdAt;

        _coverAsset = existing.coverImage.isEmpty
            ? null
            : MediaAsset(
                name: 'Cover image',
                isVideo: false,
                url: existing.coverImage,
              );
        _imageAssets = existing.images
            .map((u) => MediaAsset(
                  name: _labelFromUrl(u),
                  isVideo: false,
                  url: u,
                ))
            .toList();
        _videoAssets = existing.videos
            .map((u) => MediaAsset(
                  name: _labelFromUrl(u),
                  isVideo: true,
                  url: u,
                ))
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load project: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_coverAsset == null) {
      setState(() => _error = 'A cover image is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _uploadProgress = 0;
    });

    try {
      final repo = ref.read(portfolioRepositoryProvider);

      setState(() => _progressLabel = 'Uploading cover image...');
      final coverUrl = await _uploadAsset(
        repo,
        _coverAsset!,
        folder: 'cover',
        fallbackExt: 'jpg',
      );

      setState(() => _progressLabel = 'Uploading gallery images...');
      final imageUrls = <String>[];
      for (var i = 0; i < _imageAssets.length; i++) {
        final asset = _imageAssets[i];
        final url = await _uploadAsset(
          repo,
          asset,
          folder: 'images',
          fallbackExt: 'jpg',
        );
        imageUrls.add(url);
        setState(() => _uploadProgress = (i + 1) / (_imageAssets.length + 1));
      }

      setState(() {
        _progressLabel = 'Uploading videos...';
        _uploadProgress = 0;
      });
      final videoUrls = <String>[];
      for (var i = 0; i < _videoAssets.length; i++) {
        final asset = _videoAssets[i];
        final url = await _uploadAsset(
          repo,
          asset,
          folder: 'videos',
          fallbackExt: 'mp4',
        );
        videoUrls.add(url);
        setState(() => _uploadProgress = (i + 1) / (_videoAssets.length + 1));
      }

      final now = DateTime.now();
      final project = ProjectModel(
        id: _projectId,
        title: _title.text.trim(),
        shortDescription: _shortDesc.text.trim(),
        fullDescription: _fullDesc.text.trim(),
        category: _category.text.trim(),
        technologies: _splitCommas(_techs.text),
        platforms: _platforms.toList(),
        coverImage: coverUrl,
        images: imageUrls,
        videos: videoUrls,
        features: _splitLines(_features.text),
        projectUrl: _trimOrNull(_projectUrl.text),
        githubUrl: _trimOrNull(_githubUrl.text),
        appStoreUrl: _trimOrNull(_appStoreUrl.text),
        playStoreUrl: _trimOrNull(_playStoreUrl.text),
        challenge: _trimOrNull(_challenge.text),
        solution: _trimOrNull(_solution.text),
        result: _trimOrNull(_result.text),
        isFeatured: _isFeatured,
        isPublished: _isPublished,
        viewsCount: _viewsCount,
        createdAt: _createdAt ?? now,
        updatedAt: now,
      );

      setState(() => _progressLabel = 'Saving project...');
      await repo.saveProject(project);

      if (mounted) context.go('/admin/dashboard');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progressLabel = null;
          _uploadProgress = 0;
        });
      }
    }
  }

  /// Returns the URL for [asset], uploading it only when it is newly staged.
  Future<String> _uploadAsset(
    PortfolioRepository repo,
    MediaAsset asset, {
    required String folder,
    required String fallbackExt,
  }) async {
    final existing = asset.url;
    if (existing != null) return existing;

    final bytes = asset.bytes;
    if (bytes == null) {
      throw StateError('${asset.name} has no data to upload.');
    }

    void onProgress(double p) => setState(() => _uploadProgress = p);

    if (asset.isVideo) {
      final ext = _extensionOf(asset.name, fallbackExt);
      return repo.uploadVideo(
        bytes: bytes,
        path: _storagePath(folder, '${_uuid.v4()}.$ext'),
        contentType: _videoContentType(ext),
        onProgress: onProgress,
      );
    }

    // The compressor always emits JPEG, so the extension is fixed.
    return repo.uploadCompressedImage(
      bytes: bytes,
      path: _storagePath(folder, '${_uuid.v4()}.jpg'),
      onProgress: onProgress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Project' : 'New Project')),
      body: ResponsiveContainer(
        maxWidth: 760,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.space24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        ErrorState(message: _error!),
                        const SizedBox(height: AppConstants.space16),
                      ],
                      ..._basicFields(),
                      ..._mediaFields(),
                      ..._linkFields(),
                      ..._platformFields(),
                      ..._metaFields(),
                      ..._actions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _basicFields() => <Widget>[
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Project Title *'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _category,
          decoration: const InputDecoration(labelText: 'Category *'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Category is required' : null,
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _shortDesc,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Short Description *'),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Short description is required'
              : null,
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _fullDesc,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Full Description'),
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _techs,
          decoration: const InputDecoration(
              labelText: 'Technologies (comma separated)'),
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _features,
          maxLines: 3,
          decoration:
              const InputDecoration(labelText: 'Key Features (one per line)'),
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _challenge,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Challenge (the problem this project solves)'),
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _solution,
          maxLines: 3,
          decoration:
              const InputDecoration(labelText: 'Solution (how it was solved)'),
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _result,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Results (measurable outcome / impact)'),
        ),
        const SizedBox(height: AppConstants.space24),
      ];

  List<Widget> _mediaFields() => <Widget>[
        const Text(
          'Media',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppConstants.space4),
        const Text(
          'Images are compressed before upload. Videos must be under 25 MB.',
          style: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppConstants.space16),
        MediaPickerField(
          label: 'Cover image *',
          kind: MediaKind.image,
          assets: _coverAsset == null ? const <MediaAsset>[] : [_coverAsset!],
          onChanged: (list) =>
              setState(() => _coverAsset = list.isEmpty ? null : list.first),
          hint: 'Shown on project cards and at the top of the detail page.',
        ),
        const SizedBox(height: AppConstants.space20),
        MediaPickerField(
          label: 'Gallery images',
          kind: MediaKind.image,
          multiple: true,
          assets: _imageAssets,
          onChanged: (list) => setState(() => _imageAssets = list),
          hint: 'Screenshots and additional artwork for the detail page.',
        ),
        const SizedBox(height: AppConstants.space20),
        MediaPickerField(
          label: 'Videos',
          kind: MediaKind.video,
          multiple: true,
          assets: _videoAssets,
          onChanged: (list) => setState(() => _videoAssets = list),
          hint: 'MP4, MOV, WebM or MKV, each under 25 MB.',
        ),
        const SizedBox(height: AppConstants.space24),
      ];

  List<Widget> _linkFields() => <Widget>[
        const Text(
          'Links',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppConstants.space12),
        TextFormField(
          controller: _projectUrl,
          decoration: const InputDecoration(labelText: 'Live Project URL'),
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _githubUrl,
          decoration: const InputDecoration(labelText: 'Repository URL'),
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _appStoreUrl,
          decoration: const InputDecoration(labelText: 'App Store URL'),
        ),
        const SizedBox(height: AppConstants.space16),
        TextFormField(
          controller: _playStoreUrl,
          decoration: const InputDecoration(labelText: 'Google Play URL'),
        ),
        const SizedBox(height: AppConstants.space20),
      ];

  List<Widget> _platformFields() => <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Platforms',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        const SizedBox(height: AppConstants.space8),
        Wrap(
          spacing: AppConstants.space8,
          runSpacing: AppConstants.space8,
          children: kProjectPlatforms.map((platform) {
            return FilterChip(
              label: Text(platform),
              selected: _platforms.contains(platform),
              onSelected: (selected) => setState(() {
                if (selected) {
                  _platforms.add(platform);
                } else {
                  _platforms.remove(platform);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.space20),
      ];

  List<Widget> _metaFields() => <Widget>[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isPublished,
          onChanged: (v) => setState(() => _isPublished = v),
          title: const Text(
            'Published',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          subtitle: const Text(
            'Visible on the public portfolio',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isFeatured,
          onChanged: (v) => setState(() => _isFeatured = v),
          title: const Text(
            'Featured',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          subtitle: const Text(
            'Highlighted on the home page',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
        ),
        const SizedBox(height: AppConstants.space12),
      ];

  List<Widget> _actions() => <Widget>[
        if (_saving) ...[
          LinearProgressIndicator(
            value: _uploadProgress == 0 ? null : _uploadProgress,
          ),
          const SizedBox(height: AppConstants.space8),
          Text(
            _progressLabel ?? 'Working...',
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppConstants.space12),
        ],
        AppButton(
          label: _isEditing ? 'Save Changes' : 'Create Project',
          icon: Icons.save_rounded,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
        const SizedBox(height: AppConstants.space8),
        AppButton(
          label: 'Cancel',
          isSecondary: true,
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ];
}