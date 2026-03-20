// lib/models/chapter.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Chapter {
  final String? id;          // Firestore document ID
  final String mangaId;      // ID truyện (local SQLite id hoặc Firestore id)
  final String mangaTitle;
  final int chapterNumber;
  final String title;        // VD: "Chương 1: Khởi đầu"
  final List<String> imageUrls; // Danh sách URL ảnh các trang
  final int pageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;

  Chapter({
    this.id,
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterNumber,
    this.title = '',
    this.imageUrls = const [],
    this.pageCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPublished = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get displayTitle =>
      title.isNotEmpty ? title : 'Chương $chapterNumber';

  // ─── Firestore ───────────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'manga_id': mangaId,
      'manga_title': mangaTitle,
      'chapter_number': chapterNumber,
      'title': title,
      'image_urls': imageUrls,
      'page_count': imageUrls.length,
      'is_published': isPublished,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    };
  }

  factory Chapter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chapter(
      id: doc.id,
      mangaId: data['manga_id'] as String? ?? '',
      mangaTitle: data['manga_title'] as String? ?? '',
      chapterNumber: data['chapter_number'] as int? ?? 0,
      title: data['title'] as String? ?? '',
      imageUrls: List<String>.from(data['image_urls'] as List? ?? []),
      pageCount: data['page_count'] as int? ?? 0,
      isPublished: data['is_published'] as bool? ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ─── Local Map (để hiển thị trong cache) ────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'manga_id': mangaId,
      'manga_title': mangaTitle,
      'chapter_number': chapterNumber,
      'title': title,
      'image_urls': imageUrls.join('|||'),
      'page_count': pageCount,
      'is_published': isPublished ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Chapter copyWith({
    String? id,
    String? mangaId,
    String? mangaTitle,
    int? chapterNumber,
    String? title,
    List<String>? imageUrls,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
  }) {
    return Chapter(
      id: id ?? this.id,
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      imageUrls: imageUrls ?? this.imageUrls,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

/// Trạng thái đọc chapter của user
class ChapterReadState {
  final String userId;
  final String chapterId;
  final String mangaId;
  final int lastPage;
  final bool isCompleted;
  final DateTime readAt;

  ChapterReadState({
    required this.userId,
    required this.chapterId,
    required this.mangaId,
    required this.lastPage,
    this.isCompleted = false,
    DateTime? readAt,
  }) : readAt = readAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
        'user_id': userId,
        'chapter_id': chapterId,
        'manga_id': mangaId,
        'last_page': lastPage,
        'is_completed': isCompleted,
        'read_at': Timestamp.fromDate(readAt),
      };

  factory ChapterReadState.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChapterReadState(
      userId: d['user_id'] as String,
      chapterId: d['chapter_id'] as String,
      mangaId: d['manga_id'] as String,
      lastPage: d['last_page'] as int? ?? 0,
      isCompleted: d['is_completed'] as bool? ?? false,
      readAt: (d['read_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
