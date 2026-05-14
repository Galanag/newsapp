import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:newsapp/core/providers/providers.dart';
import 'package:newsapp/core/theme/app_theme.dart';
import 'package:newsapp/core/widgets/widgets.dart';
import 'package:newsapp/models/models.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../core/providers/providers.dart';
// import '../../../core/widgets/widgets.dart';
// import '../../models/models.dart';
// import '../../services/firebase_services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(feedNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() =>
      ref.read(feedNotifierProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _HomeAppBar(currentUser: currentUser),
      body: feedState.when(
        loading: () => _LoadingFeed(),
        error: (err, _) => AppErrorWidget(
          message: 'Failed to load feed.',
          onRetry: _onRefresh,
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.newspaper_rounded,
              title: 'No posts yet',
              subtitle: 'Be the first to share a story!',
              actionLabel: 'Create Post',
              onAction: () => context.push('/create-post'),
            );
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: AppTheme.surfaceElevated,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Guest prompt
                if (currentUser == null || currentUser.isGuest)
                  SliverToBoxAdapter(
                    child: GuestPromptBanner(
                      onRegister: () => context.push('/register'),
                    ),
                  ),

                // Category chips
                SliverToBoxAdapter(child: _CategoryChips()),

                // Feed
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                      );
                    }
                    final post = posts[index];
                    return PostCard(
                      post: post,
                      index: index,
                      onTap: () => context.push('/post/${post.postId}'),
                      onAuthorTap: () => context.push('/user/${post.authorId}'),
                      onLike: () => _handleLike(post, currentUser),
                      onComment: () => context.push('/post/${post.postId}'),
                      onShare: () {},
                    );
                  }, childCount: posts.length + 1),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLike(Post post, AppUser? user) async {
    if (user == null || user.isGuest) {
      context.push('/login');
      return;
    }
    final postService = ref.read(postServiceProvider);
    final isLiked = !post.isLikedByCurrentUser;
    ref
        .read(feedNotifierProvider.notifier)
        .toggleLike(post.postId, user.uid, isLiked);
    if (isLiked) {
      await postService.likePost(post.postId, user.uid);
    } else {
      await postService.unlikePost(post.postId, user.uid);
    }
  }
}

class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final AppUser? currentUser;
  const _HomeAppBar({this.currentUser});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            AppLogo(size: 32),
            const SizedBox(width: 10),
            Text(
              'NewsApp',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {},
              style: IconButton.styleFrom(foregroundColor: AppTheme.onSurface),
            ),
            IconButton(
              icon: const Icon(Icons.live_tv_outlined),
              onPressed: () {},
              style: IconButton.styleFrom(foregroundColor: AppTheme.primary),
              tooltip: 'Live',
            ),
            if (currentUser != null && !currentUser!.isGuest)
              UserAvatar(
                photoUrl: currentUser!.photoUrl,
                name: currentUser!.displayName,
                radius: 16,
                onTap: () => context.go('/profile'),
              )
            else
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign In'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatefulWidget {
  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  final _categories = [
    'All',
    'Breaking',
    'Politics',
    'Tech',
    'Sports',
    'Health',
    'Business',
    'Entertainment',
  ];
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isSelected = cat == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.divider,
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1A0F00)
                      : AppTheme.onSurfaceMid,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

class _LoadingFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) => const PostCardShimmer(),
    );
  }
}
