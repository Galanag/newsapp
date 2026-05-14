import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User Model
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole { user, pageCreator, orgAdmin, serviceProvider, admin }

class AppUser {
  final String uid;
  final String displayName;
  final String username;
  final String email;
  final String? photoUrl;
  final String? bio;
  final UserRole role;
  final bool isGuest;
  final bool isVerified;
  final List<String> following;
  final List<String> followers;
  final int postsCount;
  final DateTime createdAt;
  final DateTime? lastSeen;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.email,
    this.photoUrl,
    this.bio,
    this.role = UserRole.user,
    this.isGuest = false,
    this.isVerified = false,
    this.following = const [],
    this.followers = const [],
    this.postsCount = 0,
    required this.createdAt,
    this.lastSeen,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      role: UserRole.values.firstWhere(
        (r) => r.name == (data['role'] ?? 'user'),
        orElse: () => UserRole.user,
      ),
      isGuest: data['isGuest'] ?? false,
      isVerified: data['isVerified'] ?? false,
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      postsCount: data['postsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'displayName': displayName,
    'username': username,
    'email': email,
    'photoUrl': photoUrl,
    'bio': bio,
    'role': role.name,
    'isGuest': isGuest,
    'isVerified': isVerified,
    'following': following,
    'followers': followers,
    'postsCount': postsCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
  };

  AppUser copyWith({
    String? displayName,
    String? username,
    String? photoUrl,
    String? bio,
    UserRole? role,
    bool? isVerified,
    List<String>? following,
    List<String>? followers,
    int? postsCount,
    DateTime? lastSeen,
  }) => AppUser(
    uid: uid,
    displayName: displayName ?? this.displayName,
    username: username ?? this.username,
    email: email,
    photoUrl: photoUrl ?? this.photoUrl,
    bio: bio ?? this.bio,
    role: role ?? this.role,
    isGuest: isGuest,
    isVerified: isVerified ?? this.isVerified,
    following: following ?? this.following,
    followers: followers ?? this.followers,
    postsCount: postsCount ?? this.postsCount,
    createdAt: createdAt,
    lastSeen: lastSeen ?? this.lastSeen,
  );

  static AppUser get guest => AppUser(
    uid: 'guest',
    displayName: 'Guest',
    username: 'guest',
    email: '',
    isGuest: true,
    createdAt: DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Model
// ─────────────────────────────────────────────────────────────────────────────

enum MediaType { none, image, video, mixed }

enum PostVisibility { public, followers, private }

class Post {
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final bool isAuthorVerified;
  final String? authorUsername;
  final String? orgId;

  final String textContent;
  final List<String> mediaUrls;
  final MediaType mediaType;

  final PostVisibility visibility;
  final bool isPromoted;
  final bool isBreaking;

  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;

  final List<String> tags;
  final String? category;

  final DateTime timestamp;
  final DateTime? editedAt;

  final bool isLikedByCurrentUser;
  final bool isBookmarkedByCurrentUser;

  const Post({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    this.isAuthorVerified = false,
    this.authorUsername,
    this.orgId,
    required this.textContent,
    this.mediaUrls = const [],
    this.mediaType = MediaType.none,
    this.visibility = PostVisibility.public,
    this.isPromoted = false,
    this.isBreaking = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.tags = const [],
    this.category,
    required this.timestamp,
    this.editedAt,
    this.isLikedByCurrentUser = false,
    this.isBookmarkedByCurrentUser = false,
  });

  factory Post.fromFirestore(
    DocumentSnapshot doc, {
    bool isLiked = false,
    bool isBookmarked = false,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      postId: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'],
      isAuthorVerified: data['isAuthorVerified'] ?? false,
      authorUsername: data['authorUsername'],
      orgId: data['orgId'],
      textContent: data['textContent'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaType: MediaType.values.firstWhere(
        (m) => m.name == (data['mediaType'] ?? 'none'),
        orElse: () => MediaType.none,
      ),
      visibility: PostVisibility.values.firstWhere(
        (v) => v.name == (data['visibility'] ?? 'public'),
        orElse: () => PostVisibility.public,
      ),
      isPromoted: data['isPromoted'] ?? false,
      isBreaking: data['isBreaking'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      isLikedByCurrentUser: isLiked,
      isBookmarkedByCurrentUser: isBookmarked,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'isAuthorVerified': isAuthorVerified,
    'authorUsername': authorUsername,
    'orgId': orgId,
    'textContent': textContent,
    'mediaUrls': mediaUrls,
    'mediaType': mediaType.name,
    'visibility': visibility.name,
    'isPromoted': isPromoted,
    'isBreaking': isBreaking,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'sharesCount': sharesCount,
    'viewsCount': viewsCount,
    'tags': tags,
    'category': category,
    'timestamp': Timestamp.fromDate(timestamp),
    'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
  };

  Post copyWith({
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    bool? isLikedByCurrentUser,
    bool? isBookmarkedByCurrentUser,
    String? textContent,
    List<String>? mediaUrls,
    MediaType? mediaType,
    DateTime? editedAt,
  }) => Post(
    postId: postId,
    authorId: authorId,
    authorName: authorName,
    authorPhotoUrl: authorPhotoUrl,
    isAuthorVerified: isAuthorVerified,
    authorUsername: authorUsername,
    orgId: orgId,
    textContent: textContent ?? this.textContent,
    mediaUrls: mediaUrls ?? this.mediaUrls,
    mediaType: mediaType ?? this.mediaType,
    visibility: visibility,
    isPromoted: isPromoted,
    isBreaking: isBreaking,
    likesCount: likesCount ?? this.likesCount,
    commentsCount: commentsCount ?? this.commentsCount,
    sharesCount: sharesCount ?? this.sharesCount,
    viewsCount: viewsCount ?? this.viewsCount,
    tags: tags,
    category: category,
    timestamp: timestamp,
    editedAt: editedAt ?? this.editedAt,
    isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    isBookmarkedByCurrentUser:
        isBookmarkedByCurrentUser ?? this.isBookmarkedByCurrentUser,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment Model
// ─────────────────────────────────────────────────────────────────────────────

class Comment {
  final String commentId;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final bool isAuthorVerified;
  final String text;
  final int likesCount;
  final bool isLikedByCurrentUser;
  final String? parentCommentId;
  final DateTime timestamp;

  const Comment({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    this.isAuthorVerified = false,
    required this.text,
    this.likesCount = 0,
    this.isLikedByCurrentUser = false,
    this.parentCommentId,
    required this.timestamp,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      commentId: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'],
      isAuthorVerified: data['isAuthorVerified'] ?? false,
      text: data['text'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      parentCommentId: data['parentCommentId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'postId': postId,
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'isAuthorVerified': isAuthorVerified,
    'text': text,
    'likesCount': likesCount,
    'parentCommentId': parentCommentId,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Organization Model
// ─────────────────────────────────────────────────────────────────────────────

class Organization {
  final String orgId;
  final String ownerId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;
  final String? website;
  final bool isVerified;
  final int followersCount;
  final int postsCount;
  final List<String> categories;
  final DateTime createdAt;

  const Organization({
    required this.orgId,
    required this.ownerId,
    required this.name,
    this.description,
    this.logoUrl,
    this.coverUrl,
    this.website,
    this.isVerified = false,
    this.followersCount = 0,
    this.postsCount = 0,
    this.categories = const [],
    required this.createdAt,
  });

  factory Organization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Organization(
      orgId: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      logoUrl: data['logoUrl'],
      coverUrl: data['coverUrl'],
      website: data['website'],
      isVerified: data['isVerified'] ?? false,
      followersCount: data['followersCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ownerId': ownerId,
    'name': name,
    'description': description,
    'logoUrl': logoUrl,
    'coverUrl': coverUrl,
    'website': website,
    'isVerified': isVerified,
    'followersCount': followersCount,
    'postsCount': postsCount,
    'categories': categories,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Model
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationType {
  like,
  comment,
  follow,
  mention,
  postShared,
  breaking,
  system,
}

class AppNotification {
  final String notificationId;
  final String targetUid;
  final NotificationType type;
  final String? sourceUid;
  final String? sourceName;
  final String? sourcePhotoUrl;
  final String? postId;
  final String? message;
  final bool isRead;
  final DateTime timestamp;

  const AppNotification({
    required this.notificationId,
    required this.targetUid,
    required this.type,
    this.sourceUid,
    this.sourceName,
    this.sourcePhotoUrl,
    this.postId,
    this.message,
    this.isRead = false,
    required this.timestamp,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      notificationId: doc.id,
      targetUid: data['targetUid'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == (data['type'] ?? 'system'),
        orElse: () => NotificationType.system,
      ),
      sourceUid: data['sourceUid'],
      sourceName: data['sourceName'],
      sourcePhotoUrl: data['sourcePhotoUrl'],
      postId: data['postId'],
      message: data['message'],
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'targetUid': targetUid,
    'type': type.name,
    'sourceUid': sourceUid,
    'sourceName': sourceName,
    'sourcePhotoUrl': sourcePhotoUrl,
    'postId': postId,
    'message': message,
    'isRead': isRead,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
