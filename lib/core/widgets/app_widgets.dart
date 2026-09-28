import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.4,
    this.padding = const EdgeInsets.all(AppConstants.space20),
    this.borderRadius,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius =
        borderRadius ?? BorderRadius.circular(AppConstants.radiusMedium);
    final borderCol = borderColor ??
        (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);
    final bgCol = isDark
        ? AppColors.darkCard.withValues(alpha: opacity)
        : AppColors.lightCard.withValues(alpha: opacity + 0.3);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: radius,
            border: Border.all(color: borderCol, width: 1.0),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }

    return content;
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? tag;
  final bool center;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.tag,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = center ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        if (tag != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.3)),
            ),
            child: Text(
              tag!.toUpperCase(),
              style: const TextStyle(
                color: AppColors.accentCyan,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.space12),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppConstants.space12),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ],
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppConstants.space8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          );

    if (isSecondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}

/// Neutral placeholder shown when a collection has no published documents.
///
/// Displays only the supplied copy. It never substitutes sample or demo
/// content, so an empty collection can never be mistaken for real data.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.space48,
          horizontal: AppConstants.space24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.space16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, size: 32, color: AppColors.accentCyan),
              ),
              const SizedBox(height: AppConstants.space20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppConstants.space8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    height: 1.5,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppConstants.space20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when a backend read fails, so failures are visible and retryable
/// rather than silently hidden behind placeholder content.
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Unable to load content',
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.space48,
          horizontal: AppConstants.space24,
        ),
        borderColor: AppColors.error.withValues(alpha: 0.4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.space16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 32,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppConstants.space20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppConstants.space8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    height: 1.5,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppConstants.space20),
                AppButton(
                  label: 'Try Again',
                  icon: Icons.refresh_rounded,
                  isSecondary: true,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
