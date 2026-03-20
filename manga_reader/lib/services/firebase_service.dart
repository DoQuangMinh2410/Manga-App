// lib/services/firebase_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/app_user.dart';
import '../models/chapter.dart';
import '../models/manga.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Firestore Collection References ────────────────────────────────────
  CollectionReference get _usersCol => _db.collection('users');
  CollectionReference get _chaptersCol => _db.collection('chapters');
  CollectionReference get _readStatesCol => _db.collection('read_states');
  CollectionReference get _cloudMangaCol => _db.collection('manga_cloud');

  // ════════════════════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════════════════════

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<User?> get authStateStream => _auth.authStateChanges();

  /// Đăng ký bằng Email/Password
  Future<AppUser?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    await cred.user!.reload();

    final appUser = AppUser(
      uid: cred.user!.uid,
      email: email,
      displayName: displayName,
    );

    // Lưu thông tin user lên Firestore
    await _usersCol.doc(cred.user!.uid).set(appUser.toFirestore());
    return appUser;
  }

  /// Đăng nhập bằng Email/Password
  Future<AppUser?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Cập nhật lastLogin
    await _usersCol.doc(cred.user!.uid).update({
      'last_login': Timestamp.now(),
    });
    return await getUserProfile(cred.user!.uid);
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Lấy profile user từ Firestore
  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ════════════════════════════════════════════════════════════════════════
  // CHAPTERS — Firestore
  // ════════════════════════════════════════════════════════════════════════

  /// Lấy danh sách chapter của một bộ truyện
  Stream<List<Chapter>> getChaptersStream(String mangaId) {
    return _chaptersCol
        .where('manga_id', isEqualTo: mangaId)
        .where('is_published', isEqualTo: true)
        .orderBy('chapter_number', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Chapter.fromFirestore).toList());
  }

  /// Lấy danh sách chapter (Future - một lần)
  Future<List<Chapter>> getChapters(String mangaId) async {
    final snap = await _chaptersCol
        .where('manga_id', isEqualTo: mangaId)
        .where('is_published', isEqualTo: true)
        .orderBy('chapter_number', descending: false)
        .get();
    return snap.docs.map(Chapter.fromFirestore).toList();
  }

  /// Lấy một chapter cụ thể
  Future<Chapter?> getChapter(String chapterId) async {
    final doc = await _chaptersCol.doc(chapterId).get();
    if (!doc.exists) return null;
    return Chapter.fromFirestore(doc);
  }

  /// Thêm chapter mới (admin)
  Future<String> addChapter(Chapter chapter) async {
    final doc = await _chaptersCol.add(chapter.toFirestore());
    return doc.id;
  }

  /// Cập nhật chapter (admin)
  Future<void> updateChapter(Chapter chapter) async {
    await _chaptersCol.doc(chapter.id).update(chapter.toFirestore());
  }

  /// Xóa chapter (admin)
  Future<void> deleteChapter(String chapterId, {List<String>? imageUrls}) async {
    // Xóa ảnh trên Storage nếu có
    if (imageUrls != null) {
      for (final url in imageUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (_) {}
      }
    }
    await _chaptersCol.doc(chapterId).delete();
  }

  // ════════════════════════════════════════════════════════════════════════
  // FIREBASE STORAGE — Upload ảnh chapter
  // ════════════════════════════════════════════════════════════════════════

  /// Upload một ảnh lên Firebase Storage
  /// Path: chapters/{mangaId}/chapter_{num}/page_{index}.jpg
  Future<String> uploadChapterImage({
    required File imageFile,
    required String mangaId,
    required int chapterNumber,
    required int pageIndex,
  }) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final path =
        'chapters/$mangaId/chapter_$chapterNumber/page_${pageIndex.toString().padLeft(3, '0')}.$ext';
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return await task.ref.getDownloadURL();
  }

  /// Upload nhiều ảnh cho một chapter, trả về List<String> URLs
  Future<List<String>> uploadChapterImages({
    required List<File> imageFiles,
    required String mangaId,
    required int chapterNumber,
    void Function(int current, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);
      final url = await uploadChapterImage(
        imageFile: imageFiles[i],
        mangaId: mangaId,
        chapterNumber: chapterNumber,
        pageIndex: i,
      );
      urls.add(url);
    }
    return urls;
  }

  // ════════════════════════════════════════════════════════════════════════
  // READ STATE — Lưu tiến trình đọc chapter
  // ════════════════════════════════════════════════════════════════════════

  String _readStateId(String userId, String chapterId) =>
      '${userId}_$chapterId';

  /// Lưu trạng thái đọc (trang hiện tại)
  Future<void> saveReadState(ChapterReadState state) async {
    final docId = _readStateId(state.userId, state.chapterId);
    await _readStatesCol.doc(docId).set(state.toFirestore());
  }

  /// Lấy trạng thái đọc của user cho một chapter
  Future<ChapterReadState?> getReadState(
      String userId, String chapterId) async {
    final doc =
        await _readStatesCol.doc(_readStateId(userId, chapterId)).get();
    if (!doc.exists) return null;
    return ChapterReadState.fromFirestore(doc);
  }

  /// Lấy tất cả chapter đã đọc của user
  Stream<List<ChapterReadState>> getUserReadStates(String userId) {
    return _readStatesCol
        .where('user_id', isEqualTo: userId)
        .orderBy('read_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map(ChapterReadState.fromFirestore)
            .toList());
  }

  // ════════════════════════════════════════════════════════════════════════
  // CLOUD MANGA SYNC — Đồng bộ truyện lên Firestore
  // ════════════════════════════════════════════════════════════════════════

  /// Sync truyện từ SQLite lên Firestore
  Future<void> syncMangaToCloud(Manga manga, String userId) async {
    final data = {
      ...manga.toMap(),
      'user_id': userId,
      'synced_at': Timestamp.now(),
    };
    data.remove('id'); // Dùng Firestore ID thay vì SQLite id
    await _cloudMangaCol.doc('${userId}_${manga.id}').set(data);
  }

  /// Lấy truyện đã sync của user
  Future<List<Map<String, dynamic>>> getCloudManga(String userId) async {
    final snap = await _cloudMangaCol
        .where('user_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }
}
