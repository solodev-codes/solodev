import '../../core/services/analytics_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/navigation_bars.dart';
import '../../core/widgets/public_footer.dart';
import '../../data/datasources/portfolio_providers.dart';
import '../../data/models/more_models.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  /// Default fallback number if settings have not been configured yet.
  static const String defaultWhatsappNumber = '2347068009392';

  /// Mirrors `isValidEnquiry()` in `firestore.rules`. Validating against the
  /// same constraints stops the visitor submitting a document the server is
  /// guaranteed to refuse.
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _submitting = false;
  String? _status;
  bool _statusIsError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _status = null;
      _statusIsError = false;
    });

    try {
      final msg = ContactMessageModel(
        id: '',
        name: _name.text.trim(),
        email: _email.text.trim(),
        subject: _subject.text.trim(),
        message: _message.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(portfolioRepositoryProvider).submitContactMessage(msg);
      await AnalyticsService.logContactSubmit();

      _name.clear();
      _email.clear();
      _subject.clear();
      _message.clear();

      setState(() {
        _status = 'Success: your message has been sent.';
        _statusIsError = false;
      });
    } catch (error) {
      // A previous revision reported a fabricated "recorded locally" note for
      // every failure, which made a broken submission indistinguishable from a
      // working one. The server's actual reason is surfaced instead.
      setState(() {
        _status = 'Could not send: ${_describe(error)}';
        _statusIsError = true;
      });
    } finally {
      setState(() => _submitting = false);
    }
  }

  String _describe(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'the server refused it (permission-denied). The rules in '
              'firestore.rules must accept these fields.';
        case 'unavailable':
          return 'no connection. Please try again.';
        case 'failed-precondition':
          return 'a required index is missing. Check firestore.indexes.json.';
        default:
          return error.message == null
              ? error.code
              : '${error.code}: ${error.message}';
      }
    }
    return error.toString();
  }

  Future<void> _openWhatsApp(String number) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final effectiveNumber = digits.isNotEmpty ? digits : defaultWhatsappNumber;
    final uri = Uri.parse('https://wa.me/$effectiveNumber');
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() {
        _status = 'Could not open WhatsApp. Number: $effectiveNumber';
        _statusIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(portfolioSettingsProvider).valueOrNull;
    final configuredNumber = settings?.whatsappNumber.trim() ?? '';
    final hasWhatsapp = configuredNumber.isNotEmpty;
    final displayWhatsapp = hasWhatsapp ? configuredNumber : defaultWhatsappNumber;

    return Scaffold(
      appBar: const PublicNavbar(),
      drawer: const PublicDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: const ResponsiveContainer(
                child: SectionHeader(
                  tag: 'Get In Touch',
                  title: 'Let’s Build Something Amazing',
                  subtitle: 'Send an inquiry for new product development, technical architecture, or consulting.',
                ),
              ),
            ),
            ResponsiveContainer(
              maxWidth: 600,
              child: GlassCard(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_status != null) ...[
                        Text(
                          _status!,
                          style: TextStyle(
                            color: _statusIsError
                                ? AppColors.error
                                : AppColors.accentCyan,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Your Name'),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          if (value.length >= 100) {
                            return 'Name must be under 100 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Your Email'),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (!_emailPattern.hasMatch(value)) {
                            return 'A valid email address is required';
                          }
                          if (value.length >= 200) {
                            return 'Email must be under 200 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subject,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Subject required';
                          if (value.length >= 200) {
                            return 'Subject must be under 200 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _message,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Message / Project Details'),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.length < 6) {
                            return 'Message must be at least 6 characters';
                          }
                          if (value.length >= 4000) {
                            return 'Message must be under 4000 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Send Inquiry',
                        icon: Icons.send,
                        isLoading: _submitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ResponsiveContainer(
              maxWidth: 600,
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Prefer a direct conversation?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Message me on WhatsApp: $displayWhatsapp',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Chat on WhatsApp',
                      icon: Icons.chat_bubble_rounded,
                      onPressed: () => _openWhatsApp(displayWhatsapp),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
            const PublicFooter(),
          ],
        ),
      ),
    );
  }
}