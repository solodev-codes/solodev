import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/model_copy_with.dart';
import '../../data/models/more_models.dart';
import 'admin_widgets.dart';

/// Work history: create, edit, publish and delete (spec section 63).
class AdminExperienceScreen extends ConsumerWidget {
  const AdminExperienceScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ExperienceModel? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      builder: (_) => _ExperienceEditor(existing: existing),
    );
    if (saved == true) ref.invalidate(allExperiencesProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ExperienceModel item,
  ) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete this role?',
      message: '"${item.position}" at ${item.organization} is removed from the '
          'public timeline.',
    );
    if (!confirmed || !context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(portfolioRepositoryProvider).deleteExperience(item.id),
      successMessage: 'Experience deleted',
      failurePrefix: 'Could not delete',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experienceAsync = ref.watch(allExperiencesProvider);

    return AdminShell(
      title: 'Experience',
      child: experienceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(allExperiencesProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.work_outline_rounded,
                title: 'No roles yet',
                message: 'Add the positions shown on the experience timeline.',
                action: AppButton(
                  label: 'Add role',
                  icon: Icons.add_rounded,
                  onPressed: () => _openEditor(context, ref),
                ),
              ),
            );
          }

          final sorted = <ExperienceModel>[...entries]
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${sorted.length} role${sorted.length == 1 ? '' : 's'}',
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

  Widget _tile(BuildContext context, WidgetRef ref, ExperienceModel item) {
    final end = item.isCurrent || item.endDate == null
        ? 'Present'
        : DateFormat.yMMMd().format(item.endDate!);

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
                    item.position,
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
                    () => ref.read(portfolioRepositoryProvider).saveExperience(
                          item.copyWith(isPublished: !item.isPublished),
                        ),
                  ),
                ),
              ],
            ),
            Text(
              '${item.organization}  ·  '
              '${DateFormat.yMMMd().format(item.startDate)} - $end',
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

/// Create/edit sheet for one role.
class _ExperienceEditor extends ConsumerStatefulWidget {
  const _ExperienceEditor({this.existing});

  final ExperienceModel? existing;

  @override
  ConsumerState<_ExperienceEditor> createState() => _ExperienceEditorState();
}

class _ExperienceEditorState extends ConsumerState<_ExperienceEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _organization;
  late final TextEditingController _position;
  late final TextEditingController _description;
  late final TextEditingController _technologies;
  late final TextEditingController _responsibilities;

  late DateTime _startDate;
  DateTime? _endDate;
  late bool _isCurrent;
  late bool _isPublished;

  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _organization = TextEditingController(text: item?.organization ?? '');
    _position = TextEditingController(text: item?.position ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _technologies = TextEditingController(
      text: item == null ? '' : item.technologies.join(', '),
    );
    _responsibilities = TextEditingController(
      text: item == null ? '' : item.responsibilities.join('\n'),
    );
    _startDate = item?.startDate ?? DateTime.now();
    _endDate = item?.endDate;
    _isCurrent = item?.isCurrent ?? false;
    _isPublished = item?.isPublished ?? true;
  }

  @override
  void dispose() {
    _organization.dispose();
    _position.dispose();
    _description.dispose();
    _technologies.dispose();
    _responsibilities.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool forStart}) async {
    final end = _endDate;
    final now = DateTime.now();
    late final DateTime initial;
    if (forStart) {
      initial = _startDate;
    } else if (end != null) {
      initial = end;
    } else {
      initial = now.isAfter(_startDate) ? now : _startDate;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (forStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  List<String> _splitList(String raw) => raw
      .split(RegExp(r'[,;\n]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isCurrent && _endDate == null) {
      setState(() => _error = 'Set an end date, or mark the role as current.');
      return;
    }
    if (!_isCurrent && _endDate!.isBefore(_startDate)) {
      setState(() => _error = 'The end date must come after the start date.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final existing = widget.existing;
      await ref.read(portfolioRepositoryProvider).saveExperience(
            ExperienceModel(
              id: existing?.id ?? '',
              organization: _organization.text.trim(),
              position: _position.text.trim(),
              description: _description.text.trim(),
              startDate: _startDate,
              endDate: _isCurrent ? null : _endDate,
              isCurrent: _isCurrent,
              technologies: _splitList(_technologies.text),
              responsibilities: _splitList(_responsibilities.text),
              isPublished: _isPublished,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the role: $e';
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
                _isNew ? 'Add role' : 'Edit role',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.space20),
              TextFormField(
                controller: _position,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Position *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'A position is required'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _organization,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Organisation *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'An organisation is required'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _description,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Summary *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'A summary is required'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Started'),
                      child: InkWell(
                        onTap: () => _pickDate(forStart: true),
                        child: Text(
                          DateFormat.yMMMd().format(_startDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.space16),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Ended'),
                      child: InkWell(
                        onTap: _isCurrent
                            ? null
                            : () => _pickDate(forStart: false),
                        child: Text(
                          _isCurrent || _endDate == null
                              ? 'Present'
                              : DateFormat.yMMMd().format(_endDate!),
                          style: TextStyle(
                            color: _isCurrent
                                ? AppColors.textSecondaryDark
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space8),
              SwitchListTile(
                value: _isCurrent,
                onChanged: (v) => setState(() {
                  _isCurrent = v;
                  if (v) _endDate = null;
                }),
                title: const Text(
                  'I currently work here',
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
              const SizedBox(height: AppConstants.space8),
              TextFormField(
                controller: _technologies,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Technologies',
                  hintText: 'Flutter, Firebase, REST',
                  helperText: 'Comma separated.',
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _responsibilities,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Highlights',
                  hintText: 'One bullet per line',
                ),
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
                    label: _isNew ? 'Add role' : 'Save changes',
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
