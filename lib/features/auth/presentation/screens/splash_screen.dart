import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:newsapp/core/theme/app_theme.dart';
import 'package:newsapp/core/widgets/widgets.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../core/widgets/widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: 72)
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 20),
              Text(
                'NewsApp',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                'Your world, your news.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceLow),
              ).animate(delay: 350.ms).fadeIn(),
              const SizedBox(height: 60),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
