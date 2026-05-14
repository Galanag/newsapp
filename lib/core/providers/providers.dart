import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:newsapp/models/models.dart';
import 'package:newsapp/services/firebase_services.dart';
// import '../models/models.dart';
// import '../services/firebase_services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Service Providers
// ─────────────────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userServiceProvider = Provider<UserService>((ref) => UserService());
final postServiceProvider = Provider<PostService>((ref) => PostService());
final commentServiceProvider = Provider<CommentService>(
  (ref) => CommentService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Auth State
// ─────────────────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AppUser?>((ref) async* {
  final authService = ref.read(authServiceProvider);
  await for (final firebaseUser in authService.authStateChanges) {
    if (firebaseUser == null) {
      yield null;
    } else {
      final appUser = await authService.getCurrentAppUser();
      yield appUser;
    }
  }
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthService _authService;

  void _init() {
    _authService.authStateChanges.listen((user) async {
      if (user == null) {
        state = const AsyncValue.data(null);
      } else {
        final appUser = await _authService.getCurrentAppUser();
        state = AsyncValue.data(appUser);
      }
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        username: username,
      ),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Feed State
// ─────────────────────────────────────────────────────────────────────────────

class FeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  FeedNotifier(this._postService) : super(const AsyncValue.loading()) {
    loadFeed();
  }

  final PostService _postService;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  Future<void> loadFeed() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _postService.fetchFeedPage());
  }

  Future<void> refresh() => loadFeed();

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final currentPosts = state.valueOrNull ?? [];
    _isLoadingMore = true;

    try {
      final newPosts = await _postService.fetchFeedPage(pageSize: 15);
      if (newPosts.length < 15) _hasMore = false;
      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (e) {
      // keep current state on error
    } finally {
      _isLoadingMore = false;
    }
  }

  void toggleLike(String postId, String uid, bool isLiked) {
    final posts = state.valueOrNull ?? [];
    state = AsyncValue.data(
      posts.map((p) {
        if (p.postId != postId) return p;
        return p.copyWith(
          isLikedByCurrentUser: isLiked,
          likesCount: isLiked ? p.likesCount + 1 : p.likesCount - 1,
        );
      }).toList(),
    );
  }
}

final feedNotifierProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<Post>>>(
  (ref) => FeedNotifier(ref.read(postServiceProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Post Detail
// ─────────────────────────────────────────────────────────────────────────────

final postDetailProvider = StreamProvider.family<Post?, String>((ref, postId) {
  return ref.read(postServiceProvider).watchPost(postId);
});

final commentsProvider = StreamProvider.family<List<Comment>, String>((
  ref,
  postId,
) {
  return ref.read(commentServiceProvider).watchComments(postId);
});

// ─────────────────────────────────────────────────────────────────────────────
// User Profile
// ─────────────────────────────────────────────────────────────────────────────

final userProfileProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  return ref.read(userServiceProvider).watchUser(uid);
});

final userPostsProvider = FutureProvider.family<List<Post>, String>((ref, uid) {
  return ref.read(postServiceProvider).getUserPosts(uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, uid) {
  return ref.read(notificationServiceProvider).watchNotifications(uid);
});

final unreadCountProvider = StreamProvider.family<int, String>((ref, uid) {
  return ref.read(notificationServiceProvider).watchUnreadCount(uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// Create Post Notifier
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostState {
  final bool isLoading;
  final String? error;
  final bool success;

  const CreatePostState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });
}

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  CreatePostNotifier(this._postService) : super(const CreatePostState());

  final PostService _postService;

  Future<void> createPost({
    required AppUser author,
    required String textContent,
    PostVisibility visibility = PostVisibility.public,
    List<String> tags = const [],
    String? category,
    bool isBreaking = false,
  }) async {
    state = const CreatePostState(isLoading: true);
    try {
      await _postService.createPost(
        author: author,
        textContent: textContent,
        visibility: visibility,
        tags: tags,
        category: category,
        isBreaking: isBreaking,
      );
      state = const CreatePostState(success: true);
    } catch (e) {
      state = CreatePostState(error: e.toString());
    }
  }

  void reset() => state = const CreatePostState();
}

final createPostProvider =
    StateNotifierProvider<CreatePostNotifier, CreatePostState>(
  (ref) => CreatePostNotifier(ref.read(postServiceProvider)),
);
