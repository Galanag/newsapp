import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth Service
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);

    final user = AppUser(
      uid: credential.user!.uid,
      displayName: displayName,
      username: username.toLowerCase(),
      email: email,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(user.uid).set(user.toFirestore());
    return user;
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(credential.user!.uid).get();
    return AppUser.fromFirestore(doc);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Service
// ─────────────────────────────────────────────────────────────────────────────

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> watchUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  Future<String> uploadAvatar(String uid, File imageFile) async {
    final ref = _storage.ref('avatars/$uid/${const Uuid().v4()}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> followUser(String currentUid, String targetUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(currentUid), {
      'following': FieldValue.arrayUnion([targetUid]),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayUnion([currentUid]),
    });
    await batch.commit();
  }

  Future<void> unfollowUser(String currentUid, String targetUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(currentUid), {
      'following': FieldValue.arrayRemove([targetUid]),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayRemove([currentUid]),
    });
    await batch.commit();
  }

  Future<List<AppUser>> searchUsers(String query) async {
    final lowerQuery = query.toLowerCase();
    final snapshot = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lowerQuery)
        .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(20)
        .get();
    return snapshot.docs.map((d) => AppUser.fromFirestore(d)).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Service
// ─────────────────────────────────────────────────────────────────────────────

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Feed
  Query<Map<String, dynamic>> get _postsRef =>
      _db.collection('posts').orderBy('timestamp', descending: true);

  Stream<List<Post>> watchFeed({int limit = 20}) => _postsRef
      .where('visibility', isEqualTo: 'public')
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => Post.fromFirestore(d)).toList());

  Future<List<Post>> fetchFeedPage({
    DocumentSnapshot? lastDocument,
    int pageSize = 15,
  }) async {
    Query query =
        _postsRef.where('visibility', isEqualTo: 'public').limit(pageSize);
    if (lastDocument != null) query = query.startAfterDocument(lastDocument);
    final snapshot = await query.get();
    return snapshot.docs
        .map((d) => Post.fromFirestore(d as DocumentSnapshot))
        .toList();
  }

  Stream<Post?> watchPost(String postId) => _db
      .collection('posts')
      .doc(postId)
      .snapshots()
      .map((doc) => doc.exists ? Post.fromFirestore(doc) : null);

  Future<List<Post>> getUserPosts(String uid) async {
    final snapshot = await _db
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((d) => Post.fromFirestore(d)).toList();
  }

  // Create
  Future<Post> createPost({
    required AppUser author,
    required String textContent,
    List<File>? imageFiles,
    File? videoFile,
    PostVisibility visibility = PostVisibility.public,
    List<String> tags = const [],
    String? category,
    bool isBreaking = false,
  }) async {
    final postId = const Uuid().v4();
    List<String> mediaUrls = [];
    MediaType mediaType = MediaType.none;

    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (final file in imageFiles) {
        final ref = _storage.ref('posts/$postId/${const Uuid().v4()}.jpg');
        await ref.putFile(file);
        mediaUrls.add(await ref.getDownloadURL());
      }
      mediaType = videoFile != null ? MediaType.mixed : MediaType.image;
    }

    if (videoFile != null) {
      final ref = _storage.ref('posts/$postId/video.mp4');
      await ref.putFile(videoFile);
      mediaUrls.add(await ref.getDownloadURL());
      if (mediaType == MediaType.none) mediaType = MediaType.video;
    }

    final post = Post(
      postId: postId,
      authorId: author.uid,
      authorName: author.displayName,
      authorPhotoUrl: author.photoUrl,
      isAuthorVerified: author.isVerified,
      authorUsername: author.username,
      textContent: textContent,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      visibility: visibility,
      isBreaking: isBreaking,
      tags: tags,
      category: category,
      timestamp: DateTime.now(),
    );

    await _db.collection('posts').doc(postId).set(post.toFirestore());
    await _db.collection('users').doc(author.uid).update({
      'postsCount': FieldValue.increment(1),
    });

    return post;
  }

  Future<void> editPost({
    required String postId,
    required String textContent,
    List<String>? tags,
  }) async {
    final updates = <String, dynamic>{
      'textContent': textContent,
      'editedAt': Timestamp.now(),
    };
    if (tags != null) updates['tags'] = tags;
    await _db.collection('posts').doc(postId).update(updates);
  }

  Future<void> deletePost(String postId, String authorId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('posts').doc(postId));
    batch.update(_db.collection('users').doc(authorId), {
      'postsCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // Interactions
  Future<void> likePost(String postId, String uid) async {
    final batch = _db.batch();
    batch.update(_db.collection('posts').doc(postId), {
      'likesCount': FieldValue.increment(1),
    });
    batch.set(
      _db.collection('posts').doc(postId).collection('likes').doc(uid),
      {'timestamp': Timestamp.now()},
    );
    await batch.commit();
  }

  Future<void> unlikePost(String postId, String uid) async {
    final batch = _db.batch();
    batch.update(_db.collection('posts').doc(postId), {
      'likesCount': FieldValue.increment(-1),
    });
    batch.delete(
      _db.collection('posts').doc(postId).collection('likes').doc(uid),
    );
    await batch.commit();
  }

  Future<bool> isPostLiked(String postId, String uid) async {
    final doc = await _db
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .get();
    return doc.exists;
  }

  Future<void> incrementViews(String postId) => _db
      .collection('posts')
      .doc(postId)
      .update({'viewsCount': FieldValue.increment(1)});
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment Service
// ─────────────────────────────────────────────────────────────────────────────

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Comment>> watchComments(String postId) => _db
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((s) => s.docs.map((d) => Comment.fromFirestore(d)).toList());

  Future<Comment> addComment({
    required String postId,
    required AppUser author,
    required String text,
    String? parentCommentId,
  }) async {
    final commentId = const Uuid().v4();
    final comment = Comment(
      commentId: commentId,
      postId: postId,
      authorId: author.uid,
      authorName: author.displayName,
      authorPhotoUrl: author.photoUrl,
      isAuthorVerified: author.isVerified,
      text: text,
      parentCommentId: parentCommentId,
      timestamp: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(
      _db.collection('posts').doc(postId).collection('comments').doc(commentId),
      comment.toFirestore(),
    );
    batch.update(_db.collection('posts').doc(postId), {
      'commentsCount': FieldValue.increment(1),
    });
    await batch.commit();

    return comment;
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('posts').doc(postId).collection('comments').doc(commentId),
    );
    batch.update(_db.collection('posts').doc(postId), {
      'commentsCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Service
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AppNotification>> watchNotifications(String uid) => _db
      .collection('notifications')
      .where('targetUid', isEqualTo: uid)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => AppNotification.fromFirestore(d)).toList());

  Stream<int> watchUnreadCount(String uid) => _db
      .collection('notifications')
      .where('targetUid', isEqualTo: uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

  Future<void> markAllRead(String uid) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('notifications')
        .where('targetUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markRead(String notificationId) => _db
      .collection('notifications')
      .doc(notificationId)
      .update({'isRead': true});

  Future<void> createNotification({
    required String targetUid,
    required NotificationType type,
    String? sourceUid,
    String? sourceName,
    String? sourcePhotoUrl,
    String? postId,
    String? message,
  }) async {
    if (targetUid == sourceUid) return; // don't notify yourself
    final notif = AppNotification(
      notificationId: const Uuid().v4(),
      targetUid: targetUid,
      type: type,
      sourceUid: sourceUid,
      sourceName: sourceName,
      sourcePhotoUrl: sourcePhotoUrl,
      postId: postId,
      message: message,
      timestamp: DateTime.now(),
    );
    await _db
        .collection('notifications')
        .doc(notif.notificationId)
        .set(notif.toFirestore());
  }
}
