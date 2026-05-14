import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? uid; // null = own profile
  const ProfileScreen({super.key, this.uid});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _targetUid {
    final currentUser = ref.read(currentUserProvider);
    return widget.uid ?? currentUser?.uid ?? '';
  }

  bool get _isOwnProfile {
    final currentUser = ref.read(currentUserProvider);
    return widget.uid == null || widget.uid == currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(_targetUid));
    final currentUser = ref.watch(currentUserProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(),
        body: AppErrorWidget(message: 'Profile not found.'),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(),
            body: AppErrorWidget(message: 'User not found.'),
          );
        }
        final isFollowing =
            currentUser?.following.contains(profile.uid) ?? false;

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, innerScrolled) => [
              _ProfileAppBar(
                profile: profile,
                isOwnProfile: _isOwnProfile,
                isFollowing: isFollowing,
                currentUser: currentUser,
                onFollow: () =>
                    _handleFollow(profile, currentUser, isFollowing),
                onEdit: () => _showEditSheet(profile),
                onSignOut: _handleSignOut,
              ),
              SliverToBoxAdapter(
                child: _ProfileInfo(profile: profile),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'About'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _PostsTab(uid: profile.uid),
                _AboutTab(profile: profile),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleFollow(
      AppUser profile, AppUser? currentUser, bool isFollowing) async {
    if (currentUser == null || currentUser.isGuest) {
      context.push('/login');
      return;
    }
    final svc = ref.read(userServiceProvider);
    if (isFollowing) {
      await svc.unfollowUser(currentUser.uid, profile.uid);
    } else {
      await svc.followUser(currentUser.uid, profile.uid);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  void _showEditSheet(AppUser profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditProfileSheet(profile: profile),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  final AppUser profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final AppUser? currentUser;
  final VoidCallback onFollow;
  final VoidCallback onEdit;
  final VoidCallback onSignOut;

  const _ProfileAppBar({
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.currentUser,
    required this.onFollow,
    required this.onEdit,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 14, color: Colors.white),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (isOwnProfile)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 16, color: Colors.white),
            ),
            onPressed: onSignOut,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover
            profile.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: profile.photoUrl!,
                    fit: BoxFit.cover,
                    color: Colors.black38,
                    colorBlendMode: BlendMode.darken,
                  )
                : Container(
                    decoration:
                        const BoxDecoration(gradient: AppTheme.primaryGradient),
                  ),
            // Bottom gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.surface],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            // Avatar + action
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 3),
                    ),
                    child: UserAvatar(
                      photoUrl: profile.photoUrl,
                      name: profile.displayName,
                      radius: 38,
                      isVerified: profile.isVerified,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isOwnProfile)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                  else
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: isFollowing ? null : AppTheme.primaryGradient,
                        color: isFollowing ? AppTheme.surfaceOverlay : null,
                        borderRadius: BorderRadius.circular(20),
                        border: isFollowing
                            ? Border.all(color: AppTheme.divider)
                            : null,
                        boxShadow: isFollowing ? [] : AppTheme.primaryGlow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: onFollow,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing
                                    ? AppTheme.onSurface
                                    : const Color(0xFF1A0F00),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Info ──────────────────────────────────────────────────────────────

class _ProfileInfo extends StatelessWidget {
  final AppUser profile;
  const _ProfileInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (profile.isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 12, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Text('Verified',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          Text(
            '@${profile.username}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceLow,
                ),
          ),
          // Role badge
          const SizedBox(height: 6),
          _RoleBadge(role: profile.role),
          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              profile.bio!,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              _StatCount(count: profile.postsCount, label: 'Posts'),
              const SizedBox(width: 24),
              _StatCount(count: profile.followers.length, label: 'Followers'),
              const SizedBox(width: 24),
              _StatCount(count: profile.following.length, label: 'Following'),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.user) return const SizedBox.shrink();
    final configs = {
      UserRole.pageCreator: (
        Icons.pages_rounded,
        'Page Creator',
        AppTheme.primary
      ),
      UserRole.orgAdmin: (Icons.domain_rounded, 'Org Admin', AppTheme.accent),
      UserRole.serviceProvider: (
        Icons.business_center_rounded,
        'Service Provider',
        AppTheme.success
      ),
      UserRole.admin: (Icons.shield_rounded, 'Admin', AppTheme.error),
    };
    final cfg = configs[role];
    if (cfg == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.$3.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cfg.$3.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.$1, size: 11, color: cfg.$3),
          const SizedBox(width: 4),
          Text(cfg.$2,
              style: TextStyle(
                  color: cfg.$3, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatCount extends StatelessWidget {
  final int count;
  final String label;
  const _StatCount({required this.count, required this.label});

  String get _formatted {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatted,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceLow,
              ),
        ),
      ],
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _PostsTab extends ConsumerWidget {
  final String uid;
  const _PostsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(uid));
    return postsAsync.when(
      loading: () => ListView.builder(
        itemCount: 4,
        itemBuilder: (_, __) => const PostCardShimmer(),
      ),
      error: (e, _) => AppErrorWidget(message: 'Could not load posts.'),
      data: (posts) {
        if (posts.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.article_outlined,
            title: 'No posts yet',
            subtitle: 'Posts will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: posts.length,
          itemBuilder: (ctx, i) => PostCard(
            post: posts[i],
            index: i,
            onTap: () => context.push('/post/${posts[i].postId}'),
            onLike: () {},
            onComment: () => context.push('/post/${posts[i].postId}'),
          ),
        );
      },
    );
  }
}

class _AboutTab extends StatelessWidget {
  final AppUser profile;
  const _AboutTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AboutCard(children: [
          _AboutRow(
            icon: Icons.alternate_email_rounded,
            label: 'Username',
            value: '@${profile.username}',
          ),
          _AboutRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile.email.isNotEmpty ? profile.email : '—',
          ),
          _AboutRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member since',
            value: _formatDate(profile.createdAt),
          ),
          _AboutRow(
            icon: Icons.work_outline_rounded,
            label: 'Role',
            value: _roleLabel(profile.role),
            isLast: true,
          ),
        ]),
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _AboutCard(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bio',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceLow,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(profile.bio!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6)),
                ],
              ),
            ),
          ]),
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) => '${[
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
        'Dec'
      ][dt.month - 1]} ${dt.year}';

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.pageCreator:
        return 'Page Creator';
      case UserRole.orgAdmin:
        return 'Organization Admin';
      case UserRole.serviceProvider:
        return 'Service Provider';
      case UserRole.admin:
        return 'Administrator';
      default:
        return 'Member';
    }
  }
}

class _AboutCard extends StatelessWidget {
  final List<Widget> children;
  const _AboutCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _AboutRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.onSurfaceLow),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceMid,
                    ),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 0.5, thickness: 0.5),
      ],
    );
  }
}

// ── Edit Profile Sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final AppUser profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  File? _newAvatar;
  bool _isSaving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final pick =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pick != null) setState(() => _newAvatar = File(pick.path));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final svc = ref.read(userServiceProvider);
      String? photoUrl = widget.profile.photoUrl;
      if (_newAvatar != null) {
        photoUrl = await svc.uploadAvatar(widget.profile.uid, _newAvatar!);
      }
      await svc.updateProfile(
        uid: widget.profile.uid,
        displayName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        photoUrl: photoUrl,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Edit Profile',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  _newAvatar != null
                      ? CircleAvatar(
                          radius: 44,
                          backgroundImage: FileImage(_newAvatar!),
                        )
                      : UserAvatar(
                          photoUrl: widget.profile.photoUrl,
                          name: widget.profile.displayName,
                          radius: 44,
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Color(0xFF1A0F00)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppTheme.onSurface),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bioCtrl,
            style: const TextStyle(color: AppTheme.onSurface),
            maxLines: 3,
            maxLength: 160,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Bio',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A0F00),
                      ),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Bar Delegate ───────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
