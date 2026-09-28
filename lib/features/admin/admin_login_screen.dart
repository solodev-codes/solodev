import 'dart:async';
import '../../core/services/messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/app_widgets.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      unawaited(MessagingService.ensureRegistered());
      if (mounted) context.go('/admin/dashboard');
    } catch (e) {
      setState(() => _error = 'Invalid credentials or connection error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ResponsiveContainer(
          maxWidth: 440,
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Solodev Admin Portal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text('Sign in to manage portfolio content',
                    style: TextStyle(color: AppColors.textSecondaryDark)),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Admin Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Authenticate',
                    isLoading: _loading,
                    onPressed: _login,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Solodev Portfolio',
                      style: TextStyle(color: AppColors.accentCyan)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
