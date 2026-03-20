// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/manga.dart';
import '../models/reading_history.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // ─── Khởi tạo Database ───────────────────────────────────────────────────────
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Bảng Manga chính
    await db.execute('''
      CREATE TABLE ${AppConstants.tableManga} (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        title           TEXT    NOT NULL,
        author          TEXT    NOT NULL,
        genre           TEXT    NOT NULL,
        status          TEXT    NOT NULL DEFAULT 'Đang tiến hành',
        description     TEXT    DEFAULT '',
        cover_url       TEXT    DEFAULT '',
        total_chapters  INTEGER DEFAULT 0,
        read_chapters   INTEGER DEFAULT 0,
        rating          REAL    DEFAULT 0.0,
        publish_year    INTEGER,
        is_favorite     INTEGER DEFAULT 0,
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL
      )
    ''');

    // Bảng Lịch sử đọc
    await db.execute('''
      CREATE TABLE ${AppConstants.tableReadingHistory} (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        manga_id        INTEGER NOT NULL,
        manga_title     TEXT    NOT NULL,
        chapter_number  INTEGER NOT NULL,
        read_at         TEXT    NOT NULL,
        progress        REAL    DEFAULT 0.0,
        FOREIGN KEY (manga_id) REFERENCES ${AppConstants.tableManga}(id) ON DELETE CASCADE
      )
    ''');

    // Index để tăng tốc tìm kiếm
    await db.execute(
      'CREATE INDEX idx_manga_title ON ${AppConstants.tableManga}(title)',
    );
    await db.execute(
      'CREATE INDEX idx_manga_genre ON ${AppConstants.tableManga}(genre)',
    );
    await db.execute(
      'CREATE INDEX idx_history_manga ON ${AppConstants.tableReadingHistory}(manga_id)',
    );

    // Thêm dữ liệu mẫu
    await _insertSampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Xử lý nâng cấp database trong tương lai
  }

  // ─── Dữ liệu mẫu ─────────────────────────────────────────────────────────────
  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();
    final sampleManga = [
      {
        'title': 'One Piece',
        'author': 'Eiichiro Oda',
        'genre': 'Adventure',
        'status': 'Đang tiến hành',
        'description': 'Câu chuyện về Monkey D. Luffy và những người bạn trên hành trình tìm kho báu One Piece để trở thành Vua Hải Tặc.',
        'cover_url': '',
        'total_chapters': 1100,
        'read_chapters': 847,
        'rating': 9.5,
        'publish_year': 1997,
        'is_favorite': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'title': 'Naruto',
        'author': 'Masashi Kishimoto',
        'genre': 'Action',
        'status': 'Hoàn thành',
        'description': 'Hành trình của Naruto Uzumaki, một ninja trẻ mang trong mình con Chín Đuôi, với ước mơ trở thành Hokage.',
        'cover_url': '',
        'total_chapters': 700,
        'read_chapters': 700,
        'rating': 9.2,
        'publish_year': 1999,
        'is_favorite': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'title': 'Attack on Titan',
        'author': 'Hajime Isayama',
        'genre': 'Drama',
        'status': 'Hoàn thành',
        'description': 'Trong thế giới bị Titan thống trị, Eren Yeager thề sẽ tiêu diệt toàn bộ Titan sau khi mẹ anh bị ăn thịt.',
        'cover_url': '',
        'total_chapters': 139,
        'read_chapters': 139,
        'rating': 9.0,
        'publish_year': 2009,
        'is_favorite': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'title': 'Demon Slayer',
        'author': 'Koyoharu Gotouge',
        'genre': 'Action',
        'status': 'Hoàn thành',
        'description': 'Tanjiro Kamado tham gia Demon Slayer Corps để tìm cách chữa lành cho em gái Nezuko, người đã bị biến thành quỷ.',
        'cover_url': '',
        'total_chapters': 205,
        'read_chapters': 150,
        'rating': 8.8,
        'publish_year': 2016,
        'is_favorite': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'title': 'My Hero Academia',
        'author': 'Kōhei Horikoshi',
        'genre': 'Action',
        'status': 'Hoàn thành',
        'description': 'Izuku Midoriya, sinh ra trong thế giới siêu anh hùng nhưng không có năng lực, quyết tâm trở thành hero vĩ đại nhất.',
        'cover_url': '',
        'total_chapters': 425,
        'read_chapters': 300,
        'rating': 8.5,
        'publish_year': 2014,
        'is_favorite': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'title': 'Tokyo Ghoul',
        'author': 'Sui Ishida',
        'genre': 'Horror',
        'status': 'Hoàn thành',
        'description': 'Ken Kaneki sống sót sau một vụ tấn công của Ghoul và trở thành nửa người nửa quỷ trong thế giới Tokyo nguy hiểm.',
        'cover_url': '',
        'total_chapters': 179,
        'read_chapters': 90,
        'rating': 8.3,
        'publish_year': 2011,
        'is_favorite': 0,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final manga in sampleManga) {
      await db.insert(AppConstants.tableManga, manga);
    }

    // Thêm lịch sử đọc mẫu
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      await db.insert(AppConstants.tableReadingHistory, {
        'manga_id': 1,
        'manga_title': 'One Piece',
        'chapter_number': 847 - i,
        'read_at': date.toIso8601String(),
        'progress': 1.0,
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // MANGA CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  // ─── Create ──────────────────────────────────────────────────────────────────
  Future<int> insertManga(Manga manga) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableManga,
      manga.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Read All ─────────────────────────────────────────────────────────────────
  Future<List<Manga>> getAllManga({
    String? searchQuery,
    String? genreFilter,
    String? statusFilter,
    String orderBy = 'updated_at',
    bool descending = true,
  }) async {
    final db = await database;
    String where = '';
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where += "(title LIKE ? OR author LIKE ?)";
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }

    if (genreFilter != null && genreFilter.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'genre = ?';
      whereArgs.add(genreFilter);
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'status = ?';
      whereArgs.add(statusFilter);
    }

    final result = await db.query(
      AppConstants.tableManga,
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '$orderBy ${descending ? 'DESC' : 'ASC'}',
    );

    return result.map((e) => Manga.fromMap(e)).toList();
  }

  // ─── Read One ─────────────────────────────────────────────────────────────────
  Future<Manga?> getMangaById(int id) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableManga,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Manga.fromMap(result.first);
  }

  // ─── Read Favorites ──────────────────────────────────────────────────────────
  Future<List<Manga>> getFavoriteManga() async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableManga,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
    return result.map((e) => Manga.fromMap(e)).toList();
  }

  // ─── Update ──────────────────────────────────────────────────────────────────
  Future<int> updateManga(Manga manga) async {
    final db = await database;
    return await db.update(
      AppConstants.tableManga,
      manga.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [manga.id],
    );
  }

  // ─── Toggle Favorite ─────────────────────────────────────────────────────────
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      AppConstants.tableManga,
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Update Read Progress ─────────────────────────────────────────────────────
  Future<int> updateReadProgress(int id, int readChapters) async {
    final db = await database;
    return await db.update(
      AppConstants.tableManga,
      {
        'read_chapters': readChapters,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────
  Future<int> deleteManga(int id) async {
    final db = await database;
    // Xóa lịch sử đọc liên quan
    await db.delete(
      AppConstants.tableReadingHistory,
      where: 'manga_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      AppConstants.tableManga,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // READING HISTORY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<int> addReadingHistory(ReadingHistory history) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableReadingHistory,
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReadingHistory>> getReadingHistory({int limit = 20}) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableReadingHistory,
      orderBy: 'read_at DESC',
      limit: limit,
    );
    return result.map((e) => ReadingHistory.fromMap(e)).toList();
  }

  Future<List<ReadingHistory>> getMangaReadingHistory(int mangaId) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableReadingHistory,
      where: 'manga_id = ?',
      whereArgs: [mangaId],
      orderBy: 'read_at DESC',
    );
    return result.map((e) => ReadingHistory.fromMap(e)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<MangaStats> getStats() async {
    final db = await database;

    // Đếm theo trạng thái
    final countResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'Hoàn thành' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'Đang tiến hành' THEN 1 ELSE 0 END) as reading,
        SUM(CASE WHEN status = 'Tạm dừng' THEN 1 ELSE 0 END) as paused,
        SUM(CASE WHEN status = 'Bị hủy' THEN 1 ELSE 0 END) as cancelled,
        SUM(read_chapters) as total_read,
        AVG(CASE WHEN rating > 0 THEN rating ELSE NULL END) as avg_rating
      FROM ${AppConstants.tableManga}
    ''');

    final counts = countResult.first;

    // Phân bố thể loại
    final genreResult = await db.rawQuery('''
      SELECT genre, COUNT(*) as count
      FROM ${AppConstants.tableManga}
      GROUP BY genre
      ORDER BY count DESC
    ''');

    final genreDistribution = <String, int>{};
    for (final row in genreResult) {
      genreDistribution[row['genre'] as String] = row['count'] as int;
    }

    // Lịch sử đọc 7 ngày gần nhất
    final today = DateTime.now();
    final weeklyReading = <DailyReading>[];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final histResult = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM ${AppConstants.tableReadingHistory}
        WHERE read_at >= ? AND read_at < ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      weeklyReading.add(DailyReading(
        date: startOfDay,
        chaptersRead: (histResult.first['count'] as int?) ?? 0,
      ));
    }

    return MangaStats(
      totalManga: (counts['total'] as int?) ?? 0,
      completedManga: (counts['completed'] as int?) ?? 0,
      readingManga: (counts['reading'] as int?) ?? 0,
      pausedManga: (counts['paused'] as int?) ?? 0,
      cancelledManga: (counts['cancelled'] as int?) ?? 0,
      totalChaptersRead: (counts['total_read'] as int?) ?? 0,
      averageRating: (counts['avg_rating'] as double?) ?? 0.0,
      genreDistribution: genreDistribution,
      weeklyReading: weeklyReading,
    );
  }

  // ─── Close Database ──────────────────────────────────────────────────────────
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
