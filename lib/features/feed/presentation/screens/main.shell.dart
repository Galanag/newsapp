import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:newsapp/core/providers/providers.dart';
import 'package:newsapp/core/theme/app_theme.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../core/providers/providers.dart';
// import '../../../core/widgets/widgets.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentUser = ref.watch(currentUserProvider);

    int currentIndex = 0;
    if (location.startsWith('/home')) {
      currentIndex = 0;
    } else if (location.startsWith('/notifications'))
      currentIndex = 1;
    else if (location.startsWith('/organizations'))
      currentIndex = 2;
    else if (location.startsWith('/profile')) currentIndex = 3;

    final unreadCount = currentUser != null
        ? ref.watch(unreadCountProvider(currentUser.uid)).valueOrNull ?? 0
        : 0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(children: [child]),
      floatingActionButton: _CreatePostFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        unreadCount: unreadCount,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/notifications');
              break;
            case 2:
              context.go('/organizations');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}

class _CreatePostFAB extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppTheme.primaryGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            final user = ref.read(currentUserProvider);
            if (user == null || user.isGuest) {
              _showGuestPrompt(context);
              return;
            }
            context.push('/create-post');
          },
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF1A0F00),
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showGuestPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to Post',
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account to start posting news, commenting, and connecting with others.',
              textAlign: TextAlign.center,
              style: Theme.of(
                ctx,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceMid),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/register');
                },
                child: const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login');
                },
                child: const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadCount;
  final void Function(int) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: const Border(
          top: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'Notifications',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
                badge: unreadCount,
              ),
              const SizedBox(width: 48), // FAB space
              _NavItem(
                icon: Icons.domain_outlined,
                activeIcon: Icons.domain_rounded,
                label: 'Orgs',
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? AppTheme.primary : AppTheme.onSurfaceLow,
                    size: 22,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: 4,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppTheme.primary : AppTheme.onSurfaceLow,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
