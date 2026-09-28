import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/media_picker.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/model_copy_with.dart';
import '../../data/models/more_models.dart';
import 'admin_widgets.dart';

/// Achievement records: create, edit, publish and delete (spec section 62).
class AdminAchievementsScreen extends ConsumerWidget {
  const AdminAchievementsScreen({super.key});

  static const List<String> categories = <String>[
    'Award',
    'Milestone',
    'Certification',
    'Publication',
    'Speaking',
  ];

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {AchievementModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      builder: (_) => _AchievementEditor(existing: existing),
    );
    if (saved == true) ref.invalidate(allAchievementsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(allAchievementsProvider);

    return AdminShell(
      title: 'Achievements',
      child: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(allAchievementsProvider),
        ),
        data: (achievements) {
          if (achievements.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No achievements yet',
                message:
                    'Add the awards and milestones shown on the achievements '
                    'timeline.',
                action: AppButton(
                  label: 'Add achievement',
                  icon: Icons.add_rounded,
                  onPressed: () => _openEditor(context, ref),
                ),
              ),
            );
          }

          final sorted = <AchievementModel>[...achievements]
            ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${sorted.length} achievement${sorted.length == 1 ? '' : 's'}',
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
                  itemBuilder: (context, index) => _tile(
                    context,
                    ref,
                    sorted[index],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AchievementModel item,
  ) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete "${item.title}"?',
      message: 'The achievement is removed from the public timeline.',
    );
    if (!confirmed || !context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(portfolioRepositoryProvider).deleteAchievement(item.id),
      successMessage: 'Achievement deleted',
      failurePrefix: 'Could not delete',
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, AchievementModel item) {
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
                    () => ref.read(portfolioRepositoryProvider).saveAchievement(
                          item.copyWith(isPublished: !item.isPublished),
                        ),
                  ),
                ),
              ],
            ),
            Text(
              '${item.category}  ·  ${DateFormat.yMMMd().format(item.date)}',
              style: const TextStyle(
                color: AppColors.accentCyan,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create/edit sheet for one achievement.
class _AchievementEditor extends ConsumerStatefulWidget {
  const _AchievementEditor({this.existing});

  final AchievementModel? existing;

  @override
  ConsumerState<_AchievementEditor> createState() => _AchievementEditorState();
}

class _AchievementEditorState extends ConsumerState<_AchievementEditor> {
  static const Uuid _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _externalUrl;

  late String _category;
  late DateTime _date;
  late bool _isFeatured;
  late bool _isPublished;

  MediaAsset? _image;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _externalUrl = TextEditingController(text: item?.externalUrl ?? '');
    _category = item?.category ?? AdminAchievementsScreen.categories.first;
    _date = item?.date ?? DateTime.now();
    _isFeatured = item?.isFeatured ?? false;
    _isPublished = item?.isPublished ?? true;

    final url = item?.imageUrl;
    if (url != null && url.isNotEmpty) {
      _image = MediaAsset(name: 'Current image', isVideo: false, url: url);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _externalUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(portfolioRepositoryProvider);
      final existing = widget.existing;

      var imageUrl = existing?.imageUrl;
      final asset = _image;
      if (asset != null) {
        if (asset.isStaged) {
          imageUrl = await repo.uploadCompressedImage(
            bytes: asset.bytes!,
            path: 'portfolio/achievements/${_uuid.v4()}.jpg',
          );
        } else if (asset.url != null) {
          imageUrl = asset.url;
        }
      }

      await repo.saveAchievement(
        AchievementModel(
          id: existing?.id ?? '',
          title: _title.text.trim(),
          description: _description.text.trim(),
          category: _category,
          date: _date,
          imageUrl: imageUrl,
          externalUrl: _externalUrl.text.trim().isEmpty
              ? null
              : _externalUrl.text.trim(),
          isFeatured: _isFeatured,
          isPublished: _isPublished,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the achievement: $e';
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
                _isNew ? 'Add achievement' : 'Edit achievement',
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
                controller: _description,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'A description is required'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                dropdownColor: AppColors.darkCard,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in AdminAchievementsScreen.categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: AppConstants.space16),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: InkWell(
                  onTap: _pickDate,
                  child: Text(
                    DateFormat.yMMMd().format(_date),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _externalUrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link to proof (optional)',
                ),
              ),
              const SizedBox(height: AppConstants.space20),
              MediaPickerField(
                label: 'Image',
                kind: MediaKind.image,
                assets: _image == null
                    ? const <MediaAsset>[]
                    : <MediaAsset>[_image!],
                onChanged: (list) =>
                    setState(() => _image = list.isEmpty ? null : list.first),
                hint: 'Compressed before upload. Leave empty to keep none.',
              ),
              const SizedBox(height: AppConstants.space8),
              SwitchListTile(
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
                title: const Text(
                  'Featured',
                  style: TextStyle(color: Colors.white),
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
              Row(
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  AppButton(
                    label: _isNew ? 'Add achievement' : 'Save changes',
                    icon: Icons.check_rounded,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
