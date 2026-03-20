// lib/models/reading_history.dart

class ReadingHistory {
  final int? id;
  final int mangaId;
  final String mangaTitle;
  final int chapterNumber;
  final DateTime readAt;
  final double progress; // 0.0 - 1.0

  ReadingHistory({
    this.id,
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterNumber,
    DateTime? readAt,
    this.progress = 0.0,
  }) : readAt = readAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'manga_id': mangaId,
      'manga_title': mangaTitle,
      'chapter_number': chapterNumber,
      'read_at': readAt.toIso8601String(),
      'progress': progress,
    };
  }

  factory ReadingHistory.fromMap(Map<String, dynamic> map) {
    return ReadingHistory(
      id: map['id'] as int?,
      mangaId: map['manga_id'] as int,
      mangaTitle: map['manga_title'] as String,
      chapterNumber: map['chapter_number'] as int,
      readAt: DateTime.parse(map['read_at'] as String),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Thống kê tổng hợp cho biểu đồ
class MangaStats {
  final int totalManga;
  final int completedManga;
  final int readingManga;
  final int pausedManga;
  final int cancelledManga;
  final int totalChaptersRead;
  final double averageRating;
  final Map<String, int> genreDistribution;
  final List<DailyReading> weeklyReading;

  MangaStats({
    required this.totalManga,
    required this.completedManga,
    required this.readingManga,
    required this.pausedManga,
    required this.cancelledManga,
    required this.totalChaptersRead,
    required this.averageRating,
    required this.genreDistribution,
    required this.weeklyReading,
  });
}

class DailyReading {
  final DateTime date;
  final int chaptersRead;

  DailyReading({required this.date, required this.chaptersRead});
}
