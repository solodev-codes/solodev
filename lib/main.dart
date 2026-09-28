import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/routing/app_router.dart';
import 'core/services/app_check_service.dart';
import 'core/services/seo/seo_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_notice.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SolodevBootstrap()));
}

/// Initialises Firebase and App Check before the router is built.
///
/// Initialisation failures are reported on screen instead of being swallowed.
/// Silently continuing would leave every backend-backed page rendering an empty
/// state, which is indistinguishable from "the admin has published nothing".
/// App Check is deliberately non-blocking: its status only adds a note to the
/// error screen when Firebase itself also failed, because unattested requests
/// are a hardening concern, not a startup failure.
class SolodevBootstrap extends StatefulWidget {
  const SolodevBootstrap({super.key});

  @override
  State<SolodevBootstrap> createState() => _SolodevBootstrapState();
}

class _SolodevBootstrapState extends State<SolodevBootstrap> {
  late final Future<_StartupResult> _initialisation = _initialise();

  static Future<_StartupResult> _initialise() async {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final appCheckNote = await AppCheckService.initialise();
    return _StartupResult(app: app, appCheckNote: appCheckNote);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupResult>(
      future: _initialisation,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              backgroundColor: AppColors.darkBackground,
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: _StartupErrorScreen(error: '${snapshot.error}'),
          );
        }

        final result = snapshot.data!;
        if (result.appCheckNote != null) {
          debugPrint('Startup note: ${result.appCheckNote}');
        }

        return const SolodevApp();
      },
    );
  }
}

class _StartupResult {
  const _StartupResult({required this.app, this.appCheckNote});

  final FirebaseApp app;
  final String? appCheckNote;
}

/// Blocking failure screen shown when Firebase cannot be reached.
class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 20),
                const Text(
                  'Backend connection unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The portfolio could not connect to its Firebase project, so '
                  'content cannot be loaded. Verify the configuration in '
                  'lib/firebase_options.dart and that the project is reachable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SolodevApp extends StatelessWidget {
  const SolodevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: SeoService.defaultTitle,
      onGenerateTitle: (_) => SeoService.defaultTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to futuristic dark
      routerConfig: appRouter,
      // Wraps every route, dialog and admin screen so a lost connection is
      // reported once, consistently, from the top of the widget tree
      // (spec section 61).
      builder: (context, child) => OfflineNoticeHost(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

