import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/media_picker.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/more_models.dart';
import 'admin_widgets.dart';

/// Editor for the site-wide copy and contact channels the public pages read
/// from `settings/default` (spec section 60).
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(portfolioSettingsProvider);

    return AdminShell(
      title: 'Site settings',
      child: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(portfolioSettingsProvider),
        ),
        data: (settings) => _SettingsForm(key: ValueKey(settings.id)),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({super.key});

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _heroTitle;
  late final TextEditingController _heroSubtitle;
  late final TextEditingController _aboutText;
  late final TextEditingController _githubUrl;
  late final TextEditingController _linkedinUrl;
  late final TextEditingController _xUrl;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;

  bool _availableForHire = false;
  List<String> _homeSections = List.of(kDefaultHomeSections);
  MediaAsset? _avatar;

  bool _loading = true;
  bool _saving = false;
  bool _sendingTest = false;
  double _progress = 0;
  String? _error;
  String? _savedMessage;

  late final TextEditingController _testEmailTo;

  @override
  void initState() {
    super.initState();
    _testEmailTo = TextEditingController();
    for (final controller in <TextEditingController>[
      _heroTitle = TextEditingController(),
      _heroSubtitle = TextEditingController(),
      _aboutText = TextEditingController(),
      _githubUrl = TextEditingController(),
      _linkedinUrl = TextEditingController(),
      _xUrl = TextEditingController(),
      _whatsapp = TextEditingController(),
      _email = TextEditingController(),
    ]) {
      controller.addListener(_clearMessages);
    }
    _hydrate();
  }

  void _clearMessages() {
    if (_savedMessage == null && _error == null) return;
    setState(() {
      _savedMessage = null;
      _error = null;
    });
  }

  /// Visible sections in admin order, followed by the hidden ones so every
  /// catalog entry is exactly one row with a visibility switch.
  List<String> get _sectionRows => [
        ..._homeSections,
        ...kHomeSectionCatalog.where((s) => !_homeSections.contains(s)),
      ];

  void _toggleSection(String id, bool show) {
    setState(() {
      final next = [..._homeSections];
      if (show) {
        next.add(id);
      } else {
        next.remove(id);
      }
      _homeSections = next;
    });
  }

  void _moveSection(int from, int to) {
    setState(() {
      final next = [..._homeSections];
      final item = next.removeAt(from);
      next.insert(to, item);
      _homeSections = next;
    });
  }

  Widget _sectionRow(String id) {
    final position = _homeSections.indexOf(id);
    final isVisible = position >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.space8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator_rounded,
                size: 18, color: AppColors.textSecondaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                kHomeSectionLabels[id] ?? id,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (isVisible) ...[
              IconButton(
                tooltip: 'Move up',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                onPressed: position == 0
                    ? null
                    : () => _moveSection(position, position - 1),
              ),
              IconButton(
                tooltip: 'Move down',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                onPressed: position == _homeSections.length - 1
                    ? null
                    : () => _moveSection(position, position + 1),
              ),
            ],
            Switch(
              value: isVisible,
              activeThumbColor: AppColors.accentCyan,
              onChanged: (v) => _toggleSection(id, v),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hydrate() async {
    final settings = await ref.read(portfolioSettingsProvider.future);
    if (!mounted) return;
    setState(() {
      _heroTitle.text = settings.heroTitle;
      _heroSubtitle.text = settings.heroSubtitle;
      _aboutText.text = settings.aboutText;
      _githubUrl.text = settings.githubUrl;
      _linkedinUrl.text = settings.linkedinUrl;
      _xUrl.text = settings.xUrl;
      _whatsapp.text = settings.whatsappNumber;
      _email.text = settings.contactEmail;
      if (_testEmailTo.text.trim().isEmpty) {
        _testEmailTo.text = settings.contactEmail;
      }
      _availableForHire = settings.availableForHire;
      _homeSections = List.of(settings.homeSections);
      if (settings.avatarUrl.isNotEmpty) {
        _avatar = MediaAsset(
          name: 'Current avatar',
          isVideo: false,
          url: settings.avatarUrl,
        );
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _testEmailTo.dispose();
    for (final controller in <TextEditingController>[
      _heroTitle,
      _heroSubtitle,
      _aboutText,
      _githubUrl,
      _linkedinUrl,
      _xUrl,
      _whatsapp,
      _email,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Sends the SMTP self-test through the `sendClientEmail` callable
  /// (spec section 59).
  Future<void> _sendTestEmail() async {
    final to = _testEmailTo.text.trim();
    if (to.isEmpty) {
      setState(
        () => _error = 'Enter the address that should receive the test e-mail.',
      );
      return;
    }
    setState(() {
      _sendingTest = true;
      _error = null;
      _savedMessage = null;
    });
    try {
      await ref
          .read(backendCallablesProvider)
          .sendClientEmail(type: 'test', to: to);
      if (mounted) {
        setState(
          () => _savedMessage =
              'Test e-mail sent to $to — check the inbox (and spam).',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = switch (e.code) {
          'resource-exhausted' =>
            'Daily e-mail limit reached — try again after midnight UTC.',
          'failed-precondition' =>
            'E-mail is not configured — set GMAIL_USER and GMAIL_APP_PASSWORD '
                'secrets, then redeploy the functions.',
          'internal' =>
            'SMTP delivery failed — check the Gmail account and App Password.',
          _ => 'Could not send the test e-mail: ${e.message ?? e.code}',
        };
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send the test e-mail: $e');
    } finally {
      if (mounted) setState(() => _sendingTest = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
      _savedMessage = null;
      _progress = 0;
    });

    try {
      final repo = ref.read(portfolioRepositoryProvider);
      final previous = await ref.read(portfolioSettingsProvider.future);

      var avatarUrl = previous.avatarUrl;
      final asset = _avatar;
      if (asset != null) {
        if (asset.isStaged) {
          setState(() => _progress = 0.1);
          avatarUrl = await repo.uploadCompressedImage(
            bytes: asset.bytes!,
            path: 'portfolio/settings/avatar.jpg',
            maxDimension: 640,
            onProgress: (p) {
              if (mounted) setState(() => _progress = 0.1 + p * 0.9);
            },
          );
        } else if (asset.url != null) {
          avatarUrl = asset.url!;
        }
      }

      final settings = PortfolioSettingsModel(
        id: previous.id,
        heroTitle: _heroTitle.text.trim(),
        heroSubtitle: _heroSubtitle.text.trim(),
        aboutText: _aboutText.text.trim(),
        avatarUrl: avatarUrl,
        githubUrl: _githubUrl.text.trim(),
        linkedinUrl: _linkedinUrl.text.trim(),
        xUrl: _xUrl.text.trim(),
        whatsappNumber: _whatsapp.text.trim(),
        contactEmail: _email.text.trim(),
        availableForHire: _availableForHire,
        homeSections: _homeSections,
      );

      await repo.saveSettings(settings);
      ref.invalidate(portfolioSettingsProvider);
      if (!mounted) return;
      setState(() => _savedMessage = 'Settings saved. The live site updates '
          'for every visitor immediately.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not save the settings: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isWide = ResponsiveLayout.isTablet(context) ||
        ResponsiveLayout.isDesktop(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  tag: '01',
                  title: 'Hero section',
                  subtitle: 'Shown at the top of the home page.',
                ),
                _field(_heroTitle, 'Hero title *',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'A hero title is required'
                        : null),
                _field(_heroSubtitle, 'Hero subtitle', maxLines: 2),
                const SizedBox(height: AppConstants.space32),
                const SectionHeader(
                  tag: '02',
                  title: 'About',
                  subtitle: 'The biography rendered on the about page.',
                ),
                _field(_aboutText, 'About text', maxLines: 8),
                const SizedBox(height: AppConstants.space32),
                const SectionHeader(
                  tag: '03',
                  title: 'Portrait',
                  subtitle: 'Used in the hero and about cards.',
                ),
                MediaPickerField(
                  label: 'Avatar image',
                  kind: MediaKind.image,
                  assets: _avatar == null
                      ? const <MediaAsset>[]
                      : <MediaAsset>[_avatar!],
                  onChanged: (list) =>
                      setState(() => _avatar = list.isEmpty ? null : list.first),
                  hint: 'A square portrait works best. Files are compressed '
                      'to 640 px before upload.',
                ),
                const SizedBox(height: AppConstants.space32),
                const SectionHeader(
                  tag: '04',
                  title: 'Contact channels',
                  subtitle: 'Leave a field empty to hide that link site-wide.',
                ),
                if (isWide)
                  Row(
                    children: [
                      Expanded(child: _field(_githubUrl, 'GitHub URL')),
                      const SizedBox(width: AppConstants.space16),
                      Expanded(child: _field(_linkedinUrl, 'LinkedIn URL')),
                    ],
                  )
                else ...[
                  _field(_githubUrl, 'GitHub URL'),
                  _field(_linkedinUrl, 'LinkedIn URL'),
                ],
                _field(_xUrl, 'X / Twitter URL'),
                if (isWide)
                  Row(
                    children: [
                      Expanded(child: _field(_whatsapp, 'WhatsApp number',
                          keyboardType: TextInputType.phone)),
                      const SizedBox(width: AppConstants.space16),
                      Expanded(
                        child: _field(
                          _email,
                          'Contact email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _field(_whatsapp, 'WhatsApp number',
                      keyboardType: TextInputType.phone),
                  _field(_email, 'Contact email',
                      keyboardType: TextInputType.emailAddress),
                ],
                const SizedBox(height: AppConstants.space16),
                SwitchListTile(
                  value: _availableForHire,
                  onChanged: (v) => setState(() => _availableForHire = v),
                  title: const Text(
                    'Available for hire',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Shows the availability badge in the public hero.',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                  activeThumbColor: AppColors.accentCyan,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppConstants.space16),
                const SectionHeader(
                  tag: 'Homepage',
                  title: 'Homepage sections',
                  subtitle: 'Control visibility and ordering (spec section 23). '
                      'Hidden sections are removed from the live homepage.',
                ),
                for (final id in _sectionRows) _sectionRow(id),
                const SizedBox(height: AppConstants.space24),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: AppConstants.space12),
                ],
                if (_savedMessage != null) ...[
                  Text(
                    _savedMessage!,
                    style: const TextStyle(color: AppColors.success),
                  ),
                  const SizedBox(height: AppConstants.space12),
                ],
                if (_saving && _progress > 0) ...[
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: AppConstants.space12),
                ],
                AppButton(
                  label: 'Save settings',
                  icon: Icons.save_outlined,
                  isLoading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: AppConstants.space32),
                const SectionHeader(
                  tag: 'Email',
                  title: 'Client e-mail (Gmail SMTP)',
                  subtitle:
                      'Sends notifications and enquiry replies through Gmail. '
                      'Use the test below to verify the bound secrets.',
                ),
                _field(
                  _testEmailTo,
                  'Test recipient e-mail',
                  keyboardType: TextInputType.emailAddress,
                ),
                AppButton(
                  label: 'Send test e-mail',
                  icon: Icons.mail_outline_rounded,
                  isLoading: _sendingTest,
                  onPressed: _sendingTest ? null : _sendTestEmail,
                ),
                const SizedBox(height: AppConstants.space48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.space16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}