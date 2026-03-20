// lib/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isAdmin; // Admin có thể upload chapter

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    DateTime? createdAt,
    DateTime? lastLogin,
    this.isAdmin = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastLogin = lastLogin ?? DateTime.now();

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
      photoUrl: user.photoURL ?? '',
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: d['email'] as String? ?? '',
      displayName: d['display_name'] as String? ?? '',
      photoUrl: d['photo_url'] as String? ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
      lastLogin: (d['last_login'] as Timestamp?)?.toDate(),
      isAdmin: d['is_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'display_name': displayName,
        'photo_url': photoUrl,
        'created_at': Timestamp.fromDate(createdAt),
        'last_login': Timestamp.fromDate(DateTime.now()),
        'is_admin': isAdmin,
      };

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }
}
