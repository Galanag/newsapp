import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final orgsProvider = StreamProvider<List<Organization>>((ref) {
  return FirebaseFirestore.instance
      .collection('organizations')
      .orderBy('followersCount', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Organization.fromFirestore(d)).toList());
});

final followedOrgIdsProvider = StateProvider<Set<String>>((ref) => {});

// ── Screen ────────────────────────────────────────────────────────────────────

class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() =>
      _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  static const _cats = [
    'All',
    'Media',
    'NGO',
    'Government',
    'Business',
    'Sports',
    'Education',
    'Health',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(orgsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Organizations'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppTheme.divider),
        ),
        actions: [
          if (currentUser != null &&
              !currentUser.isGuest &&
              (currentUser.role == UserRole.admin ||
                  currentUser.role == UserRole.orgAdmin))
            IconButton(
              icon: const Icon(Icons.add_business_rounded),
              onPressed: () => _showCreateOrgSheet(context),
              color: AppTheme.primary,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search organizations...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Category chips
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _cats[i];
                final sel = (cat == 'All' && _selectedCategory == null) ||
                    cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat == 'All' ? null : cat;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: sel ? AppTheme.primary : AppTheme.divider,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: sel
                            ? const Color(0xFF1A0F00)
                            : AppTheme.onSurfaceMid,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 0.5, thickness: 0.5),

          // List
          Expanded(
            child: orgsAsync.when(
              loading: () => _LoadingList(),
              error: (e, _) =>
                  AppErrorWidget(message: 'Could not load organizations.'),
              data: (orgs) {
                var filtered = orgs.where((o) {
                  final matchSearch = _searchQuery.isEmpty ||
                      o.name.toLowerCase().contains(_searchQuery) ||
                      (o.description?.toLowerCase().contains(_searchQuery) ??
                          false);
                  final matchCat = _selectedCategory == null ||
                      o.categories.contains(_selectedCategory);
                  return matchSearch && matchCat;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.domain_outlined,
                    title: 'No organizations found',
                    subtitle: 'Try a different search or category.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _OrgCard(
                    org: filtered[i],
                    index: i,
                    currentUser: currentUser,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateOrgSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateOrgSheet(),
    );
  }
}

// ── Org Card ──────────────────────────────────────────────────────────────────

class _OrgCard extends ConsumerStatefulWidget {
  final Organization org;
  final int index;
  final AppUser? currentUser;
  const _OrgCard({required this.org, required this.index, this.currentUser});

  @override
  ConsumerState<_OrgCard> createState() => _OrgCardState();
}

class _OrgCardState extends ConsumerState<_OrgCard> {
  bool _isFollowing = false;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _followersCount = widget.org.followersCount;
    // Check if current user follows this org
    if (widget.currentUser != null) {
      _isFollowing = widget.currentUser!.following.contains(widget.org.orgId);
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.currentUser == null || widget.currentUser!.isGuest) {
      context.push('/login');
      return;
    }

    setState(() {
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
    });

    try {
      final db = FirebaseFirestore.instance;
      if (_isFollowing) {
        await db.runTransaction((tx) async {
          tx.update(db.collection('organizations').doc(widget.org.orgId), {
            'followersCount': FieldValue.increment(1),
          });
          tx.update(db.collection('users').doc(widget.currentUser!.uid), {
            'following': FieldValue.arrayUnion([widget.org.orgId]),
          });
        });
      } else {
        await db.runTransaction((tx) async {
          tx.update(db.collection('organizations').doc(widget.org.orgId), {
            'followersCount': FieldValue.increment(-1),
          });
          tx.update(db.collection('users').doc(widget.currentUser!.uid), {
            'following': FieldValue.arrayRemove([widget.org.orgId]),
          });
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isFollowing = !_isFollowing;
        _followersCount += _isFollowing ? 1 : -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg)),
            child: widget.org.coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.org.coverUrl!,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 90,
                    decoration:
                        const BoxDecoration(gradient: AppTheme.primaryGradient),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceOverlay,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: widget.org.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: CachedNetworkImage(
                            imageUrl: widget.org.logoUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.domain_rounded,
                          color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.org.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.org.isVerified)
                            Icon(Icons.verified_rounded,
                                size: 14, color: AppTheme.accent),
                        ],
                      ),
                      if (widget.org.categories.isNotEmpty)
                        Text(
                          widget.org.categories.take(2).join(' · '),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                  ),
                        ),
                      if (widget.org.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.org.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onSurfaceMid,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 13, color: AppTheme.onSurfaceLow),
                const SizedBox(width: 4),
                Text(
                  '$_followersCount followers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceLow,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.article_outlined,
                    size: 13, color: AppTheme.onSurfaceLow),
                const SizedBox(width: 4),
                Text(
                  '${widget.org.postsCount} posts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceLow,
                      ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: _isFollowing ? null : AppTheme.primaryGradient,
                    color: _isFollowing ? Colors.transparent : null,
                    borderRadius: BorderRadius.circular(20),
                    border: _isFollowing
                        ? Border.all(color: AppTheme.divider)
                        : null,
                    boxShadow: _isFollowing ? [] : AppTheme.primaryGlow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _toggleFollow,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: _isFollowing
                                ? AppTheme.onSurface
                                : const Color(0xFF1A0F00),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
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
    )
        .animate(delay: Duration(milliseconds: widget.index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(
            begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

// ── Create Org Sheet ──────────────────────────────────────────────────────────

class _CreateOrgSheet extends ConsumerStatefulWidget {
  const _CreateOrgSheet();

  @override
  ConsumerState<_CreateOrgSheet> createState() => _CreateOrgSheetState();
}

class _CreateOrgSheetState extends ConsumerState<_CreateOrgSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final List<String> _selectedCats = [];
  bool _isCreating = false;

  static const _allCats = [
    'Media',
    'NGO',
    'Government',
    'Business',
    'Sports',
    'Education',
    'Health',
    'Technology',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isCreating = true);
    try {
      final db = FirebaseFirestore.instance;
      final orgId = db.collection('organizations').doc().id;
      final org = Organization(
        orgId: orgId,
        ownerId: user.uid,
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        website: _websiteCtrl.text.trim().isNotEmpty
            ? _websiteCtrl.text.trim()
            : null,
        categories: _selectedCats,
        createdAt: DateTime.now(),
      );
      await db.collection('organizations').doc(orgId).set(org.toFirestore());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Create Organization',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppTheme.onSurface),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Organization name *',
                prefixIcon: Icon(Icons.domain_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: AppTheme.onSurface),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _websiteCtrl,
              style: const TextStyle(color: AppTheme.onSurface),
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Website URL',
                prefixIcon: Icon(Icons.link_rounded, size: 18),
                hintText: 'https://',
              ),
            ),
            const SizedBox(height: 16),
            Text('Categories', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCats.map((cat) {
                final sel = _selectedCats.contains(cat);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel)
                      _selectedCats.remove(cat);
                    else if (_selectedCats.length < 3) _selectedCats.add(cat);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primary.withOpacity(0.15)
                          : AppTheme.surfaceOverlay,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? AppTheme.primary : AppTheme.divider,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: sel ? AppTheme.primary : AppTheme.onSurfaceMid,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _create,
                child: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF1A0F00)),
                      )
                    : const Text('Create Organization'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (_, i) => Shimmer.fromColors(
        baseColor: AppTheme.surfaceElevated,
        highlightColor: AppTheme.surfaceOverlay,
        child: Container(
          height: 220,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      ),
    );
  }
}
