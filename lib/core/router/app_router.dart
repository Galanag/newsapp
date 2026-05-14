import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newsapp/features/feed/presentation/screens/main.shell.dart';
import '../providers/providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/feed/presentation/screens/home_screen.dart';
// import '../../features/feed/presentation/screens/main_shell.dart';
import '../../features/post/presentation/screens/create_post_screen.dart';
import '../../features/post/presentation/screens/post_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/organizations/presentation/screens/organizations_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return '/splash';

      final isAuthenticated = authState.valueOrNull != null;
      final onAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';

      if (!isAuthenticated && !onAuthRoute) return '/login';
      if (isAuthenticated && onAuthRoute) return '/home';
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const SplashScreen()),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _slideTransition(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _slideTransition(state, const RegisterScreen()),
      ),

      // Main Shell (Bottom Nav)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _noTransition(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                _noTransition(state, const NotificationsScreen()),
          ),
          GoRoute(
            path: '/organizations',
            pageBuilder: (context, state) =>
                _noTransition(state, const OrganizationsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _noTransition(state, const ProfileScreen()),
          ),
        ],
      ),

      // Full Screen Routes
      GoRoute(
        path: '/create-post',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideFromBottomTransition(state, const CreatePostScreen()),
      ),
      GoRoute(
        path: '/post/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final postId = state.pathParameters['id']!;
          return _slideTransition(state, PostDetailScreen(postId: postId));
        },
      ),
      GoRoute(
        path: '/user/:uid',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return _slideTransition(state, ProfileScreen(uid: uid));
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
});

// ── Transitions ───────────────────────────────────────────────────────────────

Page<dynamic> _fadeTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

Page<dynamic> _slideTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );

Page<dynamic> _slideFromBottomTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );

Page<dynamic> _noTransition(GoRouterState state, Widget child) =>
    NoTransitionPage(key: state.pageKey, child: child);
