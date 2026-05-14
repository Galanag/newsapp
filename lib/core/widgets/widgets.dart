import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../theme/app_theme.dart';
import '../../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App Logo
// ─────────────────────────────────────────────────────────────────────────────

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Text(
          'N',
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A0F00),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Avatar
// ─────────────────────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool isVerified;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 20,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: photoUrl!,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(),
                      errorWidget: (context, url, error) =>
                          _Initials(initials: initials, radius: radius),
                    ),
                  )
                : _Initials(initials: initials, radius: radius),
          ),
          if (isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.7,
                height: radius * 0.7,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.surfaceElevated,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  size: radius * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  final double radius;
  const _Initials({required this.initials, required this.radius});

  @override
  Widget build(BuildContext context) => Text(
        initials,
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: radius * 0.55,
          fontWeight: FontWeight.w700,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Card
// ─────────────────────────────────────────────────────────────────────────────

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onAuthorTap;
  final int index;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onAuthorTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: post.isBreaking
                ? AppTheme.primary.withOpacity(0.4)
                : AppTheme.divider,
            width: post.isBreaking ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isBreaking) _BreakingBadge(),
            if (post.isPromoted) _PromotedBadge(),
            _PostHeader(post: post, onAuthorTap: onAuthorTap),
            _PostContent(post: post),
            if (post.mediaUrls.isNotEmpty) _PostMedia(post: post),
            if (post.tags.isNotEmpty) _PostTags(tags: post.tags),
            _PostActions(
              post: post,
              onLike: onLike,
              onComment: onComment,
              onShare: onShare,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _BreakingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'BREAKING NEWS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 10, right: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceOverlay,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Text(
          'Sponsored',
          style: TextStyle(
            color: AppTheme.onSurfaceLow,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  final Post post;
  final VoidCallback? onAuthorTap;
  const _PostHeader({required this.post, this.onAuthorTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          UserAvatar(
            photoUrl: post.authorPhotoUrl,
            name: post.authorName,
            radius: 18,
            isVerified: post.isAuthorVerified,
            onTap: onAuthorTap,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onAuthorTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.authorName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                      ),
                      if (post.isAuthorVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppTheme.accent,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '@${post.authorUsername ?? post.authorName.toLowerCase().replaceAll(' ', '')} · ${timeago.format(post.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceLow,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
          ),
          _PostMenu(post: post),
        ],
      ),
    );
  }
}

class _PostMenu extends StatelessWidget {
  final Post post;
  const _PostMenu({required this.post});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: AppTheme.onSurfaceLow, size: 18),
      color: AppTheme.surfaceOverlay,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        _menuItem('bookmark', Icons.bookmark_outline_rounded, 'Save Post'),
        _menuItem('share', Icons.share_outlined, 'Share'),
        _menuItem('report', Icons.flag_outlined, 'Report'),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.onSurfaceMid),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
            ),
          ],
        ),
      );
}

class _PostContent extends StatelessWidget {
  final Post post;
  const _PostContent({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.textContent.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        post.textContent,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: AppTheme.onSurface,
            ),
      ),
    );
  }
}

class _PostMedia extends StatelessWidget {
  final Post post;
  const _PostMedia({required this.post});

  @override
  Widget build(BuildContext context) {
    final urls = post.mediaUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: urls.length == 1
          ? _SingleImage(url: urls.first)
          : _ImageGrid(urls: urls),
    );
  }
}

class _SingleImage extends StatelessWidget {
  final String url;
  const _SingleImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        placeholder: (context, url) => _ImageShimmer(height: 220),
        errorWidget: (context, url, error) => _ImageError(),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> urls;
  const _ImageGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    final shown = urls.take(4).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.3,
        children: shown.asMap().entries.map((e) {
          final isLast = e.key == 3 && urls.length > 4;
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: e.value,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _ImageShimmer(height: 100),
                  errorWidget: (context, url, error) => _ImageError(),
                ),
              ),
              if (isLast)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Text(
                        '+${urls.length - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ImageShimmer extends StatelessWidget {
  final double height;
  const _ImageShimmer({required this.height});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppTheme.surfaceOverlay,
        highlightColor: AppTheme.divider,
        child: Container(height: height, color: AppTheme.surfaceOverlay),
      );
}

class _ImageError extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.surfaceOverlay,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppTheme.onSurfaceLow,
        ),
      );
}

class _PostTags extends StatelessWidget {
  final List<String> tags;
  const _PostTags({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags
            .take(5)
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike, onComment, onShare;
  const _PostActions({
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          _ActionBtn(
            icon: post.isLikedByCurrentUser
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            label: _formatCount(post.likesCount),
            color: post.isLikedByCurrentUser
                ? AppTheme.error
                : AppTheme.onSurfaceLow,
            onTap: onLike,
          ),
          _ActionBtn(
            icon: Icons.chat_bubble_outline_rounded,
            label: _formatCount(post.commentsCount),
            color: AppTheme.onSurfaceLow,
            onTap: onComment,
          ),
          _ActionBtn(
            icon: Icons.repeat_rounded,
            label: _formatCount(post.sharesCount),
            color: AppTheme.onSurfaceLow,
            onTap: onShare,
          ),
          const Spacer(),
          _ActionBtn(
            icon: Icons.bar_chart_rounded,
            label: _formatCount(post.viewsCount),
            color: AppTheme.onSurfaceLow,
            onTap: null,
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Loading Card
// ─────────────────────────────────────────────────────────────────────────────

class PostCardShimmer extends StatelessWidget {
  const PostCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceElevated,
      highlightColor: AppTheme.surfaceOverlay,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.surfaceOverlay,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(120, 14),
                    const SizedBox(height: 4),
                    _shimmerBox(80, 10),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _shimmerBox(double.infinity, 14),
            const SizedBox(height: 6),
            _shimmerBox(double.infinity, 14),
            const SizedBox(height: 6),
            _shimmerBox(200, 14),
            const SizedBox(height: 14),
            _shimmerBox(double.infinity, 180),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceOverlay,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State Widget
// ─────────────────────────────────────────────────────────────────────────────

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppTheme.onSurfaceLow,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceMid),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State Widget
// ─────────────────────────────────────────────────────────────────────────────

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceMid),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guest Prompt Banner
// ─────────────────────────────────────────────────────────────────────────────

class GuestPromptBanner extends StatelessWidget {
  final VoidCallback onRegister;

  const GuestPromptBanner({super.key, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppTheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join the Conversation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                ),
                Text(
                  'Post, comment & follow news you care about.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onRegister,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}
