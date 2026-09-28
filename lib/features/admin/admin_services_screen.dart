import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/media_picker.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/model_copy_with.dart';
import '../../data/models/service_model.dart';
import 'admin_widgets.dart';

/// The offered services catalogue (spec section 62).
class AdminServicesScreen extends ConsumerWidget {
  const AdminServicesScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ServiceModel? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      builder: (_) => _ServiceEditor(existing: existing),
    );
    if (saved == true) ref.invalidate(allServicesProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ServiceModel item,
  ) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete "${item.title}"?',
      message: 'The service is removed from the public services page.',
    );
    if (!confirmed || !context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(portfolioRepositoryProvider).deleteService(item.id),
      successMessage: 'Service deleted',
      failurePrefix: 'Could not delete',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(allServicesProvider);

    return AdminShell(
      title: 'Services',
      child: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(allServicesProvider),
        ),
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.design_services_outlined,
                title: 'No services yet',
                message: 'Add the offerings listed on the services page.',
                action: AppButton(
                  label: 'Add service',
                  icon: Icons.add_rounded,
                  onPressed: () => _openEditor(context, ref),
                ),
              ),
            );
          }

          final sorted = <ServiceModel>[...services]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${sorted.length} service${sorted.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'Add',
                      icon: Icons.add_rounded,
                      onPressed: () => _openEditor(context, ref),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.space24),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) =>
                      _tile(context, ref, sorted[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, ServiceModel item) {
    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.only(bottom: AppConstants.space12),
      child: GlassCard(
        padding: const EdgeInsets.all(AppConstants.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: item.isPublished
                          ? Colors.white
                          : AppColors.textSecondaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (item.isFeatured)
                  const Padding(
                    padding: EdgeInsets.only(right: AppConstants.space8),
                    child: Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                  ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _openEditor(context, ref, existing: item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _delete(context, ref, item),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                Switch(
                  value: item.isPublished,
                  activeThumbColor: AppColors.accentCyan,
                  onChanged: (_) => runGuarded(
                    context,
                    () => ref.read(portfolioRepositoryProvider).saveService(
                          item.copyWith(isPublished: !item.isPublished),
                        ),
                  ),
                ),
              ],
            ),
            Text(
              item.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.accentCyan,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create/edit sheet for one service offering.
class _ServiceEditor extends ConsumerStatefulWidget {
  const _ServiceEditor({this.existing});

  final ServiceModel? existing;

  @override
  ConsumerState<_ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends ConsumerState<_ServiceEditor> {
  static const Uuid _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _shortDescription;
  late final TextEditingController _fullDescription;
  late final TextEditingController _iconName;
  late final TextEditingController _technologies;
  late final TextEditingController _features;
  late final TextEditingController _benefits;
  late final TextEditingController _process;
  late final TextEditingController _sortOrder;

  late bool _isFeatured;
  late bool _isPublished;

  MediaAsset? _cover;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title ?? '');
    _shortDescription =
        TextEditingController(text: item?.shortDescription ?? '');
    _fullDescription = TextEditingController(text: item?.fullDescription ?? '');
    _iconName = TextEditingController(text: item?.iconName ?? '');
    _technologies = TextEditingController(
      text: item == null ? '' : item.technologies.join(', '),
    );
    _features = TextEditingController(
      text: item == null ? '' : item.features.join('\n'),
    );
    _benefits = TextEditingController(
      text: item == null ? '' : item.benefits.join('\n'),
    );
    _process = TextEditingController(
      text: item == null ? '' : item.process.join('\n'),
    );
    _sortOrder = TextEditingController(text: (item?.sortOrder ?? 0).toString());
    _isFeatured = item?.isFeatured ?? false;
    _isPublished = item?.isPublished ?? true;

    final url = item?.coverImage;
    if (url != null && url.isNotEmpty) {
      _cover = MediaAsset(name: 'Current image', isVideo: false, url: url);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _shortDescription.dispose();
    _fullDescription.dispose();
    _iconName.dispose();
    _technologies.dispose();
    _features.dispose();
    _benefits.dispose();
    _process.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  List<String> _splitList(String raw, {bool linesOnly = false}) => raw
      .split(linesOnly ? RegExp(r'\n') : RegExp(r'[,;\n]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(portfolioRepositoryProvider);
      final existing = widget.existing;

      var coverImage = existing?.coverImage ?? '';
      final asset = _cover;
      if (asset != null) {
        if (asset.isStaged) {
          coverImage = await repo.uploadCompressedImage(
            bytes: asset.bytes!,
            path: 'portfolio/services/${_uuid.v4()}.jpg',
          );
        } else {
          coverImage = asset.url ?? '';
        }
      }

      final now = DateTime.now();
      final created = existing?.createdAt ?? now;

      await repo.saveService(
        ServiceModel(
          id: existing?.id ?? '',
          title: _title.text.trim(),
          shortDescription: _shortDescription.text.trim(),
          fullDescription: _fullDescription.text.trim(),
          iconName: _iconName.text.trim(),
          coverImage: coverImage,
          technologies: _splitList(_technologies.text),
          features: _splitList(_features.text, linesOnly: true),
          process: _splitList(_process.text, linesOnly: true),
          benefits: _splitList(_benefits.text, linesOnly: true),
          isPublished: _isPublished,
          isFeatured: _isFeatured,
          sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
          createdAt: created,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the service: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.space24,
        right: AppConstants.space24,
        top: AppConstants.space24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppConstants.space24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isNew ? 'Add service' : 'Edit service',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.space20),
              TextFormField(
                controller: _title,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'A title is required'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _shortDescription,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'One-line summary *',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'A summary is required'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _fullDescription,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Full detail *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'The detail copy is required'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _iconName,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Icon name',
                        hintText: 'rocket',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.space16),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _sortOrder,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Order'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space20),
              MediaPickerField(
                label: 'Cover image',
                kind: MediaKind.image,
                assets: _cover == null
                    ? const <MediaAsset>[]
                    : <MediaAsset>[_cover!],
                onChanged: (list) =>
                    setState(() => _cover = list.isEmpty ? null : list.first),
                hint: 'Compressed before upload.',
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _technologies,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Technologies',
                  helperText: 'Comma separated.',
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _features,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'What you get',
                  hintText: 'One item per line',
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _benefits,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Benefits',
                  hintText: 'One item per line',
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _process,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'How it works',
                  hintText: 'One step per line',
                ),
              ),
              const SizedBox(height: AppConstants.space8),
              SwitchListTile(
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
                title: const Text(
                  'Featured',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Featured services are highlighted on the home page.',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.accentCyan,
              ),
              SwitchListTile(
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                title: const Text(
                  'Published',
                  style: TextStyle(color: Colors.white),
                ),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.accentCyan,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppConstants.space12),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: AppConstants.space20),
              AdminEditorActions(
                onCancel: () => Navigator.of(context).pop(false),
                onSave: _save,
                saveLabel: _isNew ? 'Add service' : 'Save changes',
                isSaving: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
