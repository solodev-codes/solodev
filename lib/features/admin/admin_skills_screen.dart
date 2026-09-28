import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/model_copy_with.dart';
import '../../data/models/more_models.dart';
import 'admin_widgets.dart';

/// Skill categories offered by the public skills grid.
const List<String> kSkillCategories = <String>[
  'Mobile Development',
  'Backend',
  'AI & Design',
  'Web & Tools',
];

/// Skill catalogue: create, edit, publish and drag to reorder (spec 61).
///
/// The displayed order is the stored `sortOrder`; dragging writes a new index
/// to only the documents that actually moved, so a reorder never becomes a
/// full-collection rewrite.
class AdminSkillsScreen extends ConsumerStatefulWidget {
  const AdminSkillsScreen({super.key});

  @override
  ConsumerState<AdminSkillsScreen> createState() => _AdminSkillsScreenState();
}

class _AdminSkillsScreenState extends ConsumerState<AdminSkillsScreen> {
  /// Optimistic ordering shown while the reorder write is in flight.
  List<SkillModel>? _override;
  bool _busy = false;

  List<SkillModel> _sorted(List<SkillModel> source) {
    final list = <SkillModel>[...source];
    list.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
    });
    return list;
  }

  void _snack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: isError ? AppColors.error : AppColors.darkCardBorder,
        ),
      );
  }

  Future<void> _openEditor({SkillModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      builder: (_) => _SkillEditor(existing: existing),
    );
    if (saved == true) {
      setState(() => _override = null);
      ref.invalidate(allSkillsProvider);
    }
  }

  Future<void> _togglePublished(SkillModel skill) async {
    try {
      await ref.read(portfolioRepositoryProvider).saveSkill(
            skill.copyWith(isPublished: !skill.isPublished),
          );
    } catch (e) {
      _snack('Could not update: $e', isError: true);
    }
  }

  Future<void> _delete(SkillModel skill) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete "${skill.name}"?',
      message: 'The skill is removed from the public skills grid permanently.',
    );
    if (!confirmed) return;
    try {
      await ref.read(portfolioRepositoryProvider).deleteSkill(skill.id);
      _snack('Skill deleted');
    } catch (e) {
      _snack('Could not delete: $e', isError: true);
    }
  }

  /// [newIndex] arrives already adjusted for the removal at [oldIndex], which is
  /// the contract of ReorderableListView.onReorderItem.
  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final source = _override;
    if (source == null) return;
    final target = newIndex;
    if (target == oldIndex) return;

    final reordered = <SkillModel>[...source];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(target, moved);
    setState(() => _override = reordered);

    setState(() => _busy = true);
    try {
      final repo = ref.read(portfolioRepositoryProvider);
      final writes = <Future<void>>[];
      for (var i = 0; i < reordered.length; i++) {
        final skill = reordered[i];
        if (skill.sortOrder != i) {
          writes.add(repo.saveSkill(skill.copyWith(sortOrder: i)));
        }
      }
      await Future.wait(writes);
      ref.invalidate(allSkillsProvider);
    } catch (e) {
      _snack('Could not save the new order: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _override = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(allSkillsProvider);

    return AdminShell(
      title: 'Skills',
      child: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(allSkillsProvider),
        ),
        data: (skills) {
          if (skills.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.bolt_outlined,
                title: 'No skills yet',
                message: 'Add the technologies you want highlighted on the '
                    'home page skills grid.',
                action: AppButton(
                  label: 'Add skill',
                  icon: Icons.add_rounded,
                  onPressed: () => _openEditor(),
                ),
              ),
            );
          }

          final items = _override ?? _sorted(skills);
          if (_override == null && _needsNormalisation(items)) {
            // Legacy documents were created without a sortOrder; seed one so
            // dragging has a stable baseline.
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _normalise(items));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${items.length} skill${items.length == 1 ? '' : 's'}'
                        '${_busy ? '  ·  saving order' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'Add skill',
                      icon: Icons.add_rounded,
                      onPressed: _busy ? null : () => _openEditor(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: const [
                    Icon(
                      Icons.drag_indicator_rounded,
                      size: 16,
                      color: AppColors.textSecondaryDark,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag to set the order visitors see.',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppConstants.space24),
                  itemCount: items.length,
                  onReorderItem: _busy ? null : _onReorder,
                  itemBuilder: (context, index) => _tile(items[index], index),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _needsNormalisation(List<SkillModel> items) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].sortOrder != i) return true;
    }
    return false;
  }

  Future<void> _normalise(List<SkillModel> items) async {
    final repo = ref.read(portfolioRepositoryProvider);
    final writes = <Future<void>>[];
    for (var i = 0; i < items.length; i++) {
      if (items[i].sortOrder != i) {
        writes.add(repo.saveSkill(items[i].copyWith(sortOrder: i)));
      }
    }
    if (writes.isEmpty) return;
    try {
      await Future.wait(writes);
    } catch (_) {
      // A failed seed is harmless: the next drag retries it.
    }
  }

  Widget _tile(SkillModel skill, int index) {
    return Padding(
      key: ValueKey(skill.id),
      padding: const EdgeInsets.only(bottom: AppConstants.space8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: TextStyle(
                        color: skill.isPublished
                            ? Colors.white
                            : AppColors.textSecondaryDark,
                        fontWeight: FontWeight.w700,
                        decoration: skill.isPublished
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${skill.category}  ·  ${skill.proficiency}%',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: () => _openEditor(existing: skill),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () => _delete(skill),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            Switch(
              value: skill.isPublished,
              onChanged: _busy ? null : (_) => _togglePublished(skill),
              activeThumbColor: AppColors.accentCyan,
            ),
          ],
        ),
      ),
    );
  }
}

/// Create/edit sheet for a single skill.
///
/// Pops with `true` after a successful write so the list can refresh itself.
class _SkillEditor extends ConsumerStatefulWidget {
  const _SkillEditor({this.existing});

  final SkillModel? existing;

  @override
  ConsumerState<_SkillEditor> createState() => _SkillEditorState();
}

class _SkillEditorState extends ConsumerState<_SkillEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _icon;

  late String _category;
  late double _proficiency;
  late bool _isFeatured;
  late bool _isPublished;

  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final skill = widget.existing;
    _name = TextEditingController(text: skill?.name ?? '');
    _icon = TextEditingController(text: skill?.icon ?? '');
    _category = skill?.category ?? kSkillCategories.first;
    _proficiency = (skill?.proficiency ?? 80).toDouble();
    _isFeatured = skill?.isFeatured ?? true;
    _isPublished = skill?.isPublished ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final existing = widget.existing;
      final skill = SkillModel(
        id: existing?.id ?? '',
        name: _name.text.trim(),
        category: _category,
        icon: _icon.text.trim().isEmpty ? null : _icon.text.trim(),
        proficiency: _proficiency.round(),
        isFeatured: _isFeatured,
        isPublished: _isPublished,
        // New skills join at the end of the current ordering.
        sortOrder: existing?.sortOrder ?? (await _nextSortOrder()),
      );
      await ref.read(portfolioRepositoryProvider).saveSkill(skill);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the skill: $e';
      });
    }
  }

  Future<int> _nextSortOrder() async {
    final skills = await ref.read(allSkillsProvider.future);
    if (skills.isEmpty) return 0;
    return skills.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
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
                _isNew ? 'Add skill' : 'Edit skill',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.space20),
              TextFormField(
                controller: _name,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'A skill name is required'
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
                  for (final category in kSkillCategories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _icon,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Icon name (optional)',
                  helperText: 'Leave blank unless the grid maps icon names.',
                  helperMaxLines: 1,
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              Text(
                'Proficiency: ${_proficiency.round()}%',
                style: const TextStyle(color: Colors.white),
              ),
              Slider(
                value: _proficiency,
                min: 1,
                max: 100,
                divisions: 99,
                label: '${_proficiency.round()}%',
                activeColor: AppColors.accentCyan,
                onChanged: (v) => setState(() => _proficiency = v),
              ),
              SwitchListTile(
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
                title: const Text(
                  'Featured',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Feature the strongest skills on the home grid.',
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
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
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
                    label: _isNew ? 'Add skill' : 'Save changes',
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
