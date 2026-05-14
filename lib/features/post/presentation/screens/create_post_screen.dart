import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final Post? editPost; // non-null when editing
  const CreatePostScreen({super.key, this.editPost});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();

  final List<File> _selectedImages = [];
  final List<String> _tags = [];
  PostVisibility _visibility = PostVisibility.public;
  String? _category;
  bool _isBreaking = false;
  bool _isPosting = false;

  static const int _maxChars = 1500;
  static const List<String> _categories = [
    'Politics',
    'Technology',
    'Sports',
    'Health',
    'Business',
    'Entertainment',
    'Science',
    'World',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editPost != null) {
      _textCtrl.text = widget.editPost!.textContent;
      _tags.addAll(widget.editPost!.tags);
      _visibility = widget.editPost!.visibility;
      _category = widget.editPost!.category;
      _isBreaking = widget.editPost!.isBreaking;
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.editPost != null;
  int get _charCount => _textCtrl.text.length;
  bool get _canPost =>
      _textCtrl.text.trim().isNotEmpty &&
      _charCount <= _maxChars &&
      !_isPosting;

  Future<void> _pickImages() async {
    final picks = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (picks.isEmpty) return;
    final remaining = 4 - _selectedImages.length;
    setState(() {
      _selectedImages.addAll(
        picks.take(remaining).map((x) => File(x.path)),
      );
    });
  }

  Future<void> _pickCamera() async {
    final pick = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (pick == null) return;
    setState(() => _selectedImages.add(File(pick.path)));
  }

  void _removeImage(int i) => setState(() => _selectedImages.removeAt(i));

  void _addTag(String tag) {
    final t = tag.trim().replaceAll('#', '').toLowerCase();
    if (t.isNotEmpty && !_tags.contains(t) && _tags.length < 8) {
      setState(() => _tags.add(t));
    }
    _tagCtrl.clear();
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    final user = ref.read(currentUserProvider);
    if (user == null || user.isGuest) {
      context.push('/login');
      return;
    }

    setState(() => _isPosting = true);

    try {
      if (_isEditing) {
        await ref.read(postServiceProvider).editPost(
              postId: widget.editPost!.postId,
              textContent: _textCtrl.text.trim(),
              tags: _tags,
            );
      } else {
        await ref.read(postServiceProvider).createPost(
              author: user,
              textContent: _textCtrl.text.trim(),
              imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
              visibility: _visibility,
              tags: _tags,
              category: _category,
              isBreaking: _isBreaking,
            );
        await ref.read(feedNotifierProvider.notifier).refresh();
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to ${_isEditing ? 'update' : 'post'}: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row + text input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user != null)
                          UserAvatar(
                            photoUrl: user.photoUrl,
                            name: user.displayName,
                            radius: 20,
                            isVerified: user.isVerified,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user != null) ...[
                                Text(
                                  user.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                _VisibilityChip(
                                  value: _visibility,
                                  onChanged: (v) =>
                                      setState(() => _visibility = v),
                                ),
                                const SizedBox(height: 10),
                              ],
                              TextField(
                                controller: _textCtrl,
                                focusNode: _focusNode,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onChanged: (_) => setState(() {}),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      height: 1.65,
                                    ),
                                decoration: InputDecoration(
                                  hintText: _isEditing
                                      ? 'Edit your post...'
                                      : "What's happening? Share your news...",
                                  hintStyle: TextStyle(
                                    color: AppTheme.onSurfaceLow,
                                    fontSize: 17,
                                    height: 1.6,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image previews
                  if (_selectedImages.isNotEmpty)
                    _ImagePreviews(
                      images: _selectedImages,
                      onRemove: _removeImage,
                    ).animate().fadeIn(duration: 250.ms),

                  const SizedBox(height: 12),
                  const Divider(thickness: 0.5),

                  // Options
                  _OptionsSection(
                    category: _category,
                    isBreaking: _isBreaking,
                    tags: _tags,
                    tagCtrl: _tagCtrl,
                    onCategoryTap: _showCategorySheet,
                    onBreakingToggle: (v) => setState(() => _isBreaking = v),
                    onAddTag: _addTag,
                    onRemoveTag: (t) => setState(() => _tags.remove(t)),
                    isEditing: _isEditing,
                  ),
                ],
              ),
            ),
          ),

          // Bottom toolbar
          _BottomToolbar(
            charCount: _charCount,
            maxChars: _maxChars,
            canAddImage: _selectedImages.length < 4 && !_isEditing,
            onGallery: _pickImages,
            onCamera: _pickCamera,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      leading: TextButton(
        onPressed: _isPosting ? null : () => context.pop(),
        child: Text(
          'Cancel',
          style: TextStyle(color: AppTheme.onSurfaceMid, fontSize: 15),
        ),
      ),
      leadingWidth: 80,
      title: Text(
        _isEditing ? 'Edit Post' : 'New Post',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: _canPost ? AppTheme.primaryGradient : null,
              color: _canPost ? null : AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _canPost ? AppTheme.primaryGlow : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _canPost ? _submit : null,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A0F00),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update' : 'Post',
                          style: TextStyle(
                            color: _canPost
                                ? const Color(0xFF1A0F00)
                                : AppTheme.onSurfaceLow,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: AppTheme.divider),
      ),
    );
  }

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Category',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final sel = _category == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _category = sel ? null : cat);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary : AppTheme.surfaceOverlay,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppTheme.primary : AppTheme.divider,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: sel
                              ? const Color(0xFF1A0F00)
                              : AppTheme.onSurface,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _VisibilityChip extends StatelessWidget {
  final PostVisibility value;
  final ValueChanged<PostVisibility> onChanged;
  const _VisibilityChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final icons = {
      PostVisibility.public: Icons.public_rounded,
      PostVisibility.followers: Icons.people_outline_rounded,
      PostVisibility.private: Icons.lock_outline_rounded,
    };
    final labels = {
      PostVisibility.public: 'Everyone',
      PostVisibility.followers: 'Followers',
      PostVisibility.private: 'Only me',
    };
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: PostVisibility.values.map((v) {
              return ListTile(
                leading: Icon(icons[v], color: AppTheme.primary),
                title: Text(labels[v]!),
                selected: value == v,
                selectedColor: AppTheme.primary,
                onTap: () {
                  onChanged(v);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[value]!, size: 12, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              labels[value]!,
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 12, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviews extends StatelessWidget {
  final List<File> images;
  final void Function(int) onRemove;
  const _ImagePreviews({required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                images[i],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsSection extends StatelessWidget {
  final String? category;
  final bool isBreaking;
  final List<String> tags;
  final TextEditingController tagCtrl;
  final VoidCallback onCategoryTap;
  final ValueChanged<bool> onBreakingToggle;
  final void Function(String) onAddTag;
  final void Function(String) onRemoveTag;
  final bool isEditing;

  const _OptionsSection({
    required this.category,
    required this.isBreaking,
    required this.tags,
    required this.tagCtrl,
    required this.onCategoryTap,
    required this.onBreakingToggle,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          _OptionRow(
            icon: Icons.category_outlined,
            label: 'Category',
            trailing: Text(
              category ?? 'Select',
              style: TextStyle(
                color:
                    category != null ? AppTheme.primary : AppTheme.onSurfaceLow,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onCategoryTap,
          ),

          const Divider(height: 1, thickness: 0.5),

          // Breaking news
          if (!isEditing) ...[
            _OptionToggle(
              icon: Icons.crisis_alert_rounded,
              label: 'Breaking News',
              sublabel: 'Highlights this as urgent',
              value: isBreaking,
              onChanged: onBreakingToggle,
              iconColor: AppTheme.error,
            ),
            const Divider(height: 1, thickness: 0.5),
          ],

          // Tags
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tag_rounded,
                        size: 18, color: AppTheme.onSurfaceLow),
                    const SizedBox(width: 10),
                    Text('Tags',
                        style:
                            TextStyle(color: AppTheme.onSurface, fontSize: 14)),
                    const Spacer(),
                    Text('${tags.length}/8',
                        style: TextStyle(
                            color: AppTheme.onSurfaceLow, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map((t) => _TagChip(
                              tag: t,
                              onRemove: () => onRemoveTag(t),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 8),
                if (tags.length < 8)
                  TextField(
                    controller: tagCtrl,
                    style: const TextStyle(
                        color: AppTheme.onSurface, fontSize: 14),
                    textInputAction: TextInputAction.done,
                    onSubmitted: onAddTag,
                    decoration: InputDecoration(
                      hintText: 'Type tag and press Enter...',
                      hintStyle:
                          TextStyle(color: AppTheme.onSurfaceLow, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      fillColor: AppTheme.surfaceOverlay,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppTheme.divider, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                      prefixText: '#',
                      prefixStyle: TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;
  const _OptionRow(
      {required this.icon,
      required this.label,
      required this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.onSurfaceLow),
            const SizedBox(width: 10),
            Text(label,
                style:
                    const TextStyle(color: AppTheme.onSurface, fontSize: 14)),
            const Spacer(),
            trailing,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppTheme.onSurfaceLow),
          ],
        ),
      ),
    );
  }
}

class _OptionToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color iconColor;
  const _OptionToggle(
      {required this.icon,
      required this.label,
      required this.sublabel,
      required this.value,
      required this.onChanged,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.onSurface, fontSize: 14)),
                Text(sublabel,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceLow, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;
  const _TagChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#$tag',
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 13, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final int charCount;
  final int maxChars;
  final bool canAddImage;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _BottomToolbar({
    required this.charCount,
    required this.maxChars,
    required this.canAddImage,
    required this.onGallery,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = charCount / maxChars;
    final overLimit = charCount > maxChars;
    final nearLimit = ratio > 0.8;

    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          if (canAddImage) ...[
            IconButton(
              icon: const Icon(Icons.image_outlined, size: 22),
              color: AppTheme.onSurfaceMid,
              onPressed: onGallery,
              tooltip: 'Add from gallery',
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, size: 22),
              color: AppTheme.onSurfaceMid,
              onPressed: onCamera,
              tooltip: 'Take photo',
            ),
            const Spacer(),
          ] else
            const Spacer(),
          if (charCount > 0) ...[
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (ratio).clamp(0.0, 1.0),
                    strokeWidth: 2.5,
                    backgroundColor: AppTheme.divider,
                    valueColor: AlwaysStoppedAnimation(
                      overLimit
                          ? AppTheme.error
                          : nearLimit
                              ? AppTheme.warning
                              : AppTheme.primary,
                    ),
                  ),
                  if (nearLimit)
                    Text(
                      (maxChars - charCount).toString(),
                      style: TextStyle(
                        fontSize: 9,
                        color:
                            overLimit ? AppTheme.error : AppTheme.onSurfaceMid,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
