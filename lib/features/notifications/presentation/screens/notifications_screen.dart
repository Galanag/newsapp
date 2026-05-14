import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null || currentUser.isGuest) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('Notifications')),
        body: EmptyStateWidget(
          icon: Icons.notifications_off_outlined,
          title: 'Sign in to see notifications',
          subtitle:
              'Create an account to get notified about likes, comments, and more.',
          actionLabel: 'Sign In',
          onAction: () => context.push('/login'),
        ),
      );
    }

    final notifsAsync = ref.watch(notificationsProvider(currentUser.uid));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _NotifAppBar(uid: currentUser.uid),
      body: notifsAsync.when(
        loading: () => _LoadingShimmer(),
        error: (e, _) =>
            AppErrorWidget(message: 'Could not load notifications.'),
        data: (notifs) {
          if (notifs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notifications_outlined,
              title: 'All caught up!',
              subtitle:
                  'When someone likes, comments, or follows you, you\'ll see it here.',
            );
          }

          // Group by time
          final today = <AppNotification>[];
          final thisWeek = <AppNotification>[];
          final older = <AppNotification>[];
          final now = DateTime.now();
          for (final n in notifs) {
            final diff = now.difference(n.timestamp);
            if (diff.inDays == 0)
              today.add(n);
            else if (diff.inDays <= 7)
              thisWeek.add(n);
            else
              older.add(n);
          }

          return ListView(
            children: [
              if (today.isNotEmpty) ...[
                _GroupHeader('Today'),
                ...today
                    .asMap()
                    .entries
                    .map((e) => _NotifTile(notif: e.value, index: e.key)),
              ],
              if (thisWeek.isNotEmpty) ...[
                _GroupHeader('This Week'),
                ...thisWeek.asMap().entries.map((e) =>
                    _NotifTile(notif: e.value, index: e.key + today.length)),
              ],
              if (older.isNotEmpty) ...[
                _GroupHeader('Earlier'),
                ...older.asMap().entries.map((e) => _NotifTile(
                    notif: e.value,
                    index: e.key + today.length + thisWeek.length)),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
            ],
          );
        },
      ),
    );
  }
}

class _NotifAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String uid;
  const _NotifAppBar({required this.uid});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider(uid)).valueOrNull ?? 0;
    return AppBar(
      title: Row(
        children: [
          const Text('Notifications'),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : unread.toString(),
                style: const TextStyle(
                  color: Color(0xFF1A0F00),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (unread > 0)
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllRead(uid);
            },
            child: const Text('Mark all read'),
          ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, thickness: 0.5),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceLow,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _NotifTile extends ConsumerWidget {
  final AppNotification notif;
  final int index;
  const _NotifTile({required this.notif, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = _config(notif.type);

    return GestureDetector(
      onTap: () async {
        if (!notif.isRead) {
          await ref
              .read(notificationServiceProvider)
              .markRead(notif.notificationId);
        }
        if (notif.postId != null && context.mounted) {
          context.push('/post/${notif.postId}');
        } else if (notif.sourceUid != null && context.mounted) {
          context.push('/user/${notif.sourceUid}');
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: notif.isRead
            ? Colors.transparent
            : AppTheme.primary.withOpacity(0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with icon badge
            Stack(
              children: [
                UserAvatar(
                  photoUrl: notif.sourcePhotoUrl,
                  name: notif.sourceName ?? '?',
                  radius: 22,
                  onTap: notif.sourceUid != null
                      ? () => context.push('/user/${notif.sourceUid}')
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: cfg.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 1.5),
                    ),
                    child: Icon(cfg.icon, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.4),
                      children: [
                        TextSpan(
                          text: '${notif.sourceName ?? 'Someone'} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: cfg.action),
                      ],
                    ),
                  ),
                  if (notif.message != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notif.message!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMid,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notif.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceLow,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 300.ms);
  }

  _NotifConfig _config(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return _NotifConfig(
            Icons.favorite_rounded, AppTheme.error, 'liked your post');
      case NotificationType.comment:
        return _NotifConfig(Icons.chat_bubble_rounded, AppTheme.accent,
            'commented on your post');
      case NotificationType.follow:
        return _NotifConfig(Icons.person_add_rounded, AppTheme.success,
            'started following you');
      case NotificationType.mention:
        return _NotifConfig(Icons.alternate_email_rounded, AppTheme.primary,
            'mentioned you in a post');
      case NotificationType.postShared:
        return _NotifConfig(
            Icons.repeat_rounded, AppTheme.primary, 'shared your post');
      case NotificationType.breaking:
        return _NotifConfig(Icons.crisis_alert_rounded, AppTheme.error,
            'posted a breaking update');
      case NotificationType.system:
        return _NotifConfig(Icons.info_outline_rounded, AppTheme.onSurfaceMid,
            'sent a system notification');
    }
  }
}

class _NotifConfig {
  final IconData icon;
  final Color color;
  final String action;
  const _NotifConfig(this.icon, this.color, this.action);
}

class _LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => const PostCardShimmer(),
    );
  }
}
