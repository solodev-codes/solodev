import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/testimonial_model.dart';
import 'admin_widgets.dart';

/// Testimonial records: create, edit, publish and delete (spec sections 9/23).
class AdminTestimonialsScreen extends ConsumerWidget {
  const AdminTestimonialsScreen({super.key});

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {TestimonialModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      builder: (_) => _TestimonialEditor(existing: existing),
    );
    if (saved == true) ref.invalidate(allTestimonialsProvider);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, TestimonialModel item) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete this testimonial?',
      message: 'The quote from ${item.name} will be permanently removed. '
          'This cannot be undone.',
    );
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteTestimonial(item.id);
    ref.invalidate(allTestimonialsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonialsAsync = ref.watch(allTestimonialsProvider);

    return AdminShell(
      title: 'Testimonials',
      child: testimonialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(allTestimonialsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.format_quote_rounded,
                title: 'No testimonials yet',
                message:
                    'Add the words of happy clients — they appear in the '
                    'homepage testimonial wall once published.',
                action: AppButton(
                  label: 'Add testimonial',
                  icon: Icons.add_rounded,
                  onPressed: () => _openEditor(context, ref),
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${items.length} testimonial${items.length == 1 ? '' : 's'}',
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
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _tile(context, ref, items[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, TestimonialModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.space12),
      child: GlassCard(
        padding: const EdgeInsets.all(AppConstants.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!item.isPublished)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Draft',
                            style: TextStyle(
                                color: AppColors.warning, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  if (item.role.isNotEmpty)
                    Text(
                      item.role,
                      style: const TextStyle(
                          color: AppColors.accentCyan, fontSize: 12),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= item.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: const Color(0xFFFBBF24),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.yMMMd().format(item.updatedAt),
                        style: const TextStyle(
                            color: AppColors.textSecondaryDark, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.space8),
            Column(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.accentCyan),
                  onPressed: () => _openEditor(context, ref, existing: item),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  onPressed: () => _delete(context, ref, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet editor for a single testimonial.
class _TestimonialEditor extends ConsumerStatefulWidget {
  const _TestimonialEditor({this.existing});

  final TestimonialModel? existing;

  @override
  ConsumerState<_TestimonialEditor> createState() =>
      _TestimonialEditorState();
}

class _TestimonialEditorState extends ConsumerState<_TestimonialEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _content;
  late int _rating;
  late bool _published;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _role = TextEditingController(text: e?.role ?? '');
    _content = TextEditingController(text: e?.content ?? '');
    _rating = e?.rating ?? 5;
    _published = e?.isPublished ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final testimonial = TestimonialModel(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      role: _role.text.trim(),
      content: _content.text.trim(),
      rating: _rating,
      isPublished: _published,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await ref.read(portfolioRepositoryProvider).saveTestimonial(testimonial);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the testimonial: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null
                    ? 'New testimonial'
                    : 'Edit testimonial',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Client name *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'A client name is required.'
                    : null,
              ),
              const SizedBox(height: AppConstants.space12),
              TextFormField(
                controller: _role,
                decoration: const InputDecoration(
                    labelText: 'Role / company (optional)'),
              ),
              const SizedBox(height: AppConstants.space12),
              TextFormField(
                controller: _content,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'What they said *', alignLabelWithHint: true),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'The quote is required.'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              Row(
                children: [
                  const Text('Rating',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 12),
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFBBF24),
                      ),
                      onPressed: () => setState(() => _rating = i),
                    ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Published',
                    style: TextStyle(color: Colors.white)),
                value: _published,
                onChanged: (v) => setState(() => _published = v),
              ),
              const SizedBox(height: AppConstants.space12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Save',
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