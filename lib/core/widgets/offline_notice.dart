import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/portfolio_providers.dart';
import '../constants/app_colors.dart';

/// Shows a persistent offline notice above the whole app (spec section 61).
///
/// Mounted from `MaterialApp.router`'s `builder`, so it also covers the admin
/// area and every dialog. The banner overlays the content instead of changing
/// the layout, which keeps a lost connection from re-flowing the page a visitor
/// is reading.
class OfflineNoticeHost extends ConsumerWidget {
  const OfflineNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityStatusProvider);
    // While the first check is still in flight the app behaves as if online;
    // warning a visitor before the answer is known would be a false alarm.
    final isOffline = status.valueOrNull == false;

    return Stack(
      children: [
        Positioned.fill(child: child),
        if (isOffline)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _OfflineBanner(
              onRetry: () => ref.invalidate(connectivityStatusProvider),
            ),
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(AppConstants.space12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.space16,
            vertical: AppConstants.space12,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: AppConstants.space12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You appear to be offline.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Showing what was already loaded. New content will appear '
                      'when the connection returns.',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
