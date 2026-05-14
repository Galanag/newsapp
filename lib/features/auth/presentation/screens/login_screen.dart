import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:newsapp/core/providers/providers.dart';
import 'package:newsapp/core/theme/app_theme.dart';
import 'package:newsapp/core/widgets/widgets.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../core/providers/providers.dart';
// import '../../../core/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref
        .read(authNotifierProvider.notifier)
        .signIn(email: _emailCtrl.text.trim(), password: _passCtrl.text);

    if (mounted) {
      final state = ref.read(authNotifierProvider);
      state.whenOrNull(
        error: (err, _) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_friendlyError(err.toString())),
              backgroundColor: AppTheme.error,
            ),
          );
        },
      );
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Sign in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              AppLogo(size: 48)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
              const SizedBox(height: 32),
              Text(
                'Welcome\nback.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                "Sign in to stay connected with the news that matters.",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceMid),
              ).animate(delay: 180.ms).fadeIn(),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your email';
                        if (!RegExp(
                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$',
                        ).hasMatch(v)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ).animate(delay: 220.ms).fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter your password';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ).animate(delay: 280.ms).fadeIn().slideY(begin: 0.1),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ).animate(delay: 320.ms).fadeIn(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Color(0xFF1A0F00),
                                  ),
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ).animate(delay: 360.ms).fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    _Divider(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.g_mobiledata_rounded,
                              size: 22,
                              color: AppTheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            const Text('Continue with Google'),
                          ],
                        ),
                      ),
                    ).animate(delay: 400.ms).fadeIn(),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppTheme.onSurfaceMid),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 440.ms).fadeIn(),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Continue as guest',
                    style: TextStyle(
                      color: AppTheme.onSurfaceLow,
                      fontSize: 13,
                    ),
                  ),
                ),
              ).animate(delay: 480.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(authServiceProvider)
                  .sendPasswordReset(emailCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reset link sent! Check your email.'),
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.divider, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(color: AppTheme.onSurfaceLow, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.divider, thickness: 0.5)),
      ],
    );
  }
}
