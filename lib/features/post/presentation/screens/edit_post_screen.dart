// ─────────────────────────────────────────────────────────────────────────────
// EditPostScreen
// Route: /post/:id/edit
// Reuses CreatePostScreen with the editPost parameter.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import 'create_post_screen.dart';

class EditPostScreen extends ConsumerWidget {
  final String postId;
  const EditPostScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));

    return postAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(),
        body: AppErrorWidget(message: 'Post not found.'),
      ),
      data: (post) {
        if (post == null) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(),
            body: AppErrorWidget(message: 'Post not found.'),
          );
        }
        return CreatePostScreen(editPost: post);
      },
    );
  }
}
