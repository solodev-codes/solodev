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

/// Credential management for the public certificates wall (spec section 62).
class AdminCertificatesScreen extends ConsumerWidget {
  const AdminCertificatesScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CertificateModel? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      builder: (_) => _CertificateEditor(existing: existing),
    );
    if (saved == true) ref.invalidate(allCertificatesProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CertificateModel item,
  ) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete "${item.title}"?',
      message: 'The certificate is removed from the public wall.',
    );
    if (!confirmed || !context.mounted) return;
    await runGuarded(
      context,
      () => ref.read(portfolioRepositoryProvider).deleteCertificate(item.id),
      successMessage: 'Certificate deleted',
      failurePrefix: 'Could not delete',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificatesAsync = ref.watch(allCertificatesProvider);

    return AdminShell(
      title: 'Certificates',
      child: certificatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(allCertificatesProvider),
        ),
        data: (certificates) {
          if (certificates.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.workspace_premium_outlined,
                title: 'No certificates yet',
                message: 'Add the credentials displayed on the certificates '
                    'page.',
                action: AppButton(
                  label: 'Add certificate',
                  icon: Icons.add_rounded,
                  onPressed: () => _openEditor(context, ref),
                ),
              ),
            );
          }

          final sorted = <CertificateModel>[...certificates]
            ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${sorted.length} certificate${sorted.length == 1 ? '' : 's'}',
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

  Widget _tile(BuildContext context, WidgetRef ref, CertificateModel item) {
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
                    () => ref.read(portfolioRepositoryProvider).saveCertificate(
                          item.copyWith(isPublished: !item.isPublished),
                        ),
                  ),
                ),
              ],
            ),
            Text(
              '${item.issuer}  ·  '
              '${DateFormat.yMMMd().format(item.issueDate)}',
              style: const TextStyle(
                color: AppColors.accentCyan,
                fontSize: 12,
              ),
            ),
            if (item.skills.isNotEmpty) ...[
              const SizedBox(height: AppConstants.space8),
              Text(
                item.skills.join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Create/edit sheet for one certificate.
class _CertificateEditor extends ConsumerStatefulWidget {
  const _CertificateEditor({this.existing});

  final CertificateModel? existing;

  @override
  ConsumerState<_CertificateEditor> createState() => _CertificateEditorState();
}

class _CertificateEditorState extends ConsumerState<_CertificateEditor> {
  static const Uuid _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _issuer;
  late final TextEditingController _description;
  late final TextEditingController _credentialId;
  late final TextEditingController _credentialUrl;
  late final TextEditingController _skills;

  late DateTime _issueDate;
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
    _issuer = TextEditingController(text: item?.issuer ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _credentialId = TextEditingController(text: item?.credentialId ?? '');
    _credentialUrl = TextEditingController(text: item?.credentialUrl ?? '');
    _skills = TextEditingController(text: item?.skills.join(', ') ?? '');
    _issueDate = item?.issueDate ?? DateTime.now();
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
    _issuer.dispose();
    _description.dispose();
    _credentialId.dispose();
    _credentialUrl.dispose();
    _skills.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _issueDate = picked);
  }

  List<String> _splitList(String raw) => raw
      .split(RegExp(r'[,;\n]'))
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

      var imageUrl = existing?.imageUrl ?? '';
      final asset = _image;
      if (asset != null) {
        if (asset.isStaged) {
          imageUrl = await repo.uploadCompressedImage(
            bytes: asset.bytes!,
            path: 'portfolio/certificates/${_uuid.v4()}.jpg',
          );
        } else {
          imageUrl = asset.url ?? '';
        }
      }

      await repo.saveCertificate(
        CertificateModel(
          id: existing?.id ?? '',
          title: _title.text.trim(),
          issuer: _issuer.text.trim(),
          description: _description.text.trim(),
          imageUrl: imageUrl,
          credentialUrl: _credentialUrl.text.trim().isEmpty
              ? null
              : _credentialUrl.text.trim(),
          credentialId: _credentialId.text.trim().isEmpty
              ? null
              : _credentialId.text.trim(),
          issueDate: _issueDate,
          skills: _splitList(_skills.text),
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
        _error = 'Could not save the certificate: $e';
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
                _isNew ? 'Add certificate' : 'Edit certificate',
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
                controller: _issuer,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Issuing organisation *',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'An issuer is required'
                    : null,
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _description,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: AppConstants.space16),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Issue date'),
                child: InkWell(
                  onTap: _pickDate,
                  child: Text(
                    DateFormat.yMMMd().format(_issueDate),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _credentialId,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Credential ID (optional)',
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _credentialUrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Verify at (optional)',
                ),
              ),
              const SizedBox(height: AppConstants.space16),
              TextFormField(
                controller: _skills,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Skills',
                  hintText: 'Flutter, Firebase, CI/CD',
                  helperText: 'Comma separated.',
                ),
              ),
              const SizedBox(height: AppConstants.space20),
              MediaPickerField(
                label: 'Certificate image',
                kind: MediaKind.image,
                assets: _image == null
                    ? const <MediaAsset>[]
                    : <MediaAsset>[_image!],
                onChanged: (list) =>
                    setState(() => _image = list.isEmpty ? null : list.first),
                hint: 'Compressed before upload.',
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
              AdminEditorActions(
                onCancel: () => Navigator.of(context).pop(false),
                onSave: _save,
                saveLabel: _isNew ? 'Add certificate' : 'Save changes',
                isSaving: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
