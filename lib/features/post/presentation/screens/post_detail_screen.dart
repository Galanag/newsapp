import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:newsapp/core/providers/providers.dart';
import 'package:newsapp/core/theme/app_theme.dart';
import 'package:newsapp/core/widgets/widgets.dart';
import 'package:newsapp/models/models.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
// import '../../../core/theme/app_theme.dart';
// import '../../../core/providers/providers.dart';
// import '../../../core/widgets/widgets.dart';
// import '../../models/models.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSendingComment = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {
              final post = postAsync.valueOrNull;
              if (post != null) {
                Share.share(post.textContent);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => AppErrorWidget(message: 'Post not found.'),
        data: (post) {
          if (post == null) return AppErrorWidget(message: 'Post not found.');
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    // Post content
                    SliverToBoxAdapter(child: _PostDetailBody(post: post)),

                    // Divider
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Comments',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceOverlay,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                post.commentsCount.toString(),
                                style: TextStyle(
                                  color: AppTheme.onSurfaceMid,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Comments
                    commentsAsync.when(
                      loading: () => const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      error: (e, _) => SliverToBoxAdapter(
                        child: AppErrorWidget(
                          message: 'Failed to load comments.',
                        ),
                      ),
                      data: (comments) {
                        if (comments.isEmpty) {
                          return SliverToBoxAdapter(
                            child: EmptyStateWidget(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'No comments yet',
                              subtitle: 'Be the first to share your thoughts!',
                            ),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _CommentTile(
                              comment: comments[i],
                              index: i,
                              currentUid: currentUser?.uid,
                            ),
                            childCount: comments.length,
                          ),
                        );
                      },
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),

              // Comment input
              _CommentInput(
                controller: _commentCtrl,
                isSending: _isSendingComment,
                currentUser: currentUser,
                onSend: () => _sendComment(post),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendComment(Post post) async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.isGuest) {
      context.push('/login');
      return;
    }
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      await ref
          .read(commentServiceProvider)
          .addComment(postId: post.postId, author: user, text: text);
      _commentCtrl.clear();
    } finally {
      setState(() => _isSendingComment = false);
    }
  }
}

class _PostDetailBody extends ConsumerWidget {
  final Post post;
  const _PostDetailBody({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              UserAvatar(
                photoUrl: post.authorPhotoUrl,
                name: post.authorName,
                radius: 22,
                isVerified: post.isAuthorVerified,
                onTap: () => context.push('/user/${post.authorId}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.authorName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (post.isAuthorVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppTheme.accent,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '@${post.authorUsername} · ${timeago.format(post.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (post.authorId == currentUser?.uid)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () {},
                  color: AppTheme.onSurfaceLow,
                ),
            ],
          ),

          // Breaking badge
          if (post.isBreaking) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '🔴 BREAKING NEWS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],

          // Content
          if (post.textContent.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              post.textContent,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.65),
            ),
          ],

          // Media
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...post.mediaUrls.map(
              (url) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],

          // Tags
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: post.tags
                  .map(
                    (tag) => GestureDetector(
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Timestamp
          const SizedBox(height: 12),
          Text(
            _formatFullDate(post.timestamp),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceLow),
          ),
          if (post.editedAt != null)
            Text(
              'Edited ${timeago.format(post.editedAt!)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceLow),
            ),

          const Divider(height: 24, thickness: 0.5),

          // Stats row
          Row(
            children: [
              _StatItem(count: post.likesCount, label: 'Likes'),
              const SizedBox(width: 20),
              _StatItem(count: post.commentsCount, label: 'Comments'),
              const SizedBox(width: 20),
              _StatItem(count: post.sharesCount, label: 'Shares'),
            ],
          ),

          const Divider(height: 16, thickness: 0.5),

          // Actions
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: post.isLikedByCurrentUser
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  label: 'Like',
                  isActive: post.isLikedByCurrentUser,
                  color: post.isLikedByCurrentUser
                      ? AppTheme.error
                      : AppTheme.onSurfaceLow,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment',
                  isActive: false,
                  color: AppTheme.onSurfaceLow,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  isActive: false,
                  color: AppTheme.onSurfaceLow,
                  onTap: () => Share.share(post.textContent),
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bookmark_outline_rounded,
                  label: 'Save',
                  isActive: post.isBookmarkedByCurrentUser,
                  color: post.isBookmarkedByCurrentUser
                      ? AppTheme.primary
                      : AppTheme.onSurfaceLow,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm · ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: count.toString(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
          ),
          TextSpan(
            text: ' $label',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final int index;
  final String? currentUid;
  const _CommentTile({
    required this.comment,
    required this.index,
    this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            photoUrl: comment.authorPhotoUrl,
            name: comment.authorName,
            radius: 16,
            isVerified: comment.isAuthorVerified,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.authorName,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: AppTheme.onSurface),
                          ),
                          if (comment.isAuthorVerified) ...[
                            const SizedBox(width: 3),
                            Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: AppTheme.accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    children: [
                      Text(
                        timeago.format(comment.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Like',
                          style: TextStyle(
                            color: AppTheme.onSurfaceLow,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: AppTheme.onSurfaceLow,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (comment.authorId == currentUid) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 300.ms);
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final AppUser? currentUser;
  final VoidCallback onSend;

  const _CommentInput({
    required this.controller,
    required this.isSending,
    required this.currentUser,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          if (currentUser != null)
            UserAvatar(
              photoUrl: currentUser!.photoUrl,
              name: currentUser!.displayName,
              radius: 16,
            )
          else
            const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.onSurfaceLow,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: currentUser == null || currentUser!.isGuest
                    ? 'Sign in to comment...'
                    : 'Write a comment...',
                hintStyle: TextStyle(
                  color: AppTheme.onSurfaceLow,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                filled: true,
                fillColor: AppTheme.surfaceOverlay,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppTheme.divider,
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.primaryGlow,
              ),
              child: isSending
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF1A0F00),
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
