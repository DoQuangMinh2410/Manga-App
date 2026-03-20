// lib/utils/constants.dart

class AppConstants {
  // App Info
  static const String appName = 'MangaVerse';
  static const String appVersion = '1.0.0';

  // SharedPreferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyDefaultView = 'default_view';
  static const String keyReadingFont = 'reading_font_size';

  // Database
  static const String dbName = 'manga_reader.db';
  static const int dbVersion = 1;

  // Table Names
  static const String tableManga = 'manga';
  static const String tableReadingHistory = 'reading_history';
  static const String tableFavorites = 'favorites';

  // Manga Status
  static const List<String> mangaStatuses = [
    'Đang tiến hành',
    'Hoàn thành',
    'Tạm dừng',
    'Bị hủy',
  ];

  // Manga Genres
  static const List<String> mangaGenres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
    'Isekai',
    'Mecha',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ];

  // View Modes
  static const String viewGrid = 'grid';
  static const String viewList = 'list';

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
}
