// lib/providers/manga_provider.dart
import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../models/reading_history.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../utils/constants.dart';

enum MangaLoadingState { idle, loading, loaded, error }

class MangaProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final PreferencesService _prefsService;

  MangaProvider(this._dbService, this._prefsService);

  // ─── State ───────────────────────────────────────────────────────────────────
  MangaLoadingState _loadingState = MangaLoadingState.idle;
  List<Manga> _mangaList = [];
  List<Manga> _filteredList = [];
  MangaStats? _stats;
  String _searchQuery = '';
  String _selectedGenre = '';
  String _selectedStatus = '';
  String _viewMode = AppConstants.viewGrid;
  String _errorMessage = '';
  bool _statsLoading = false;

  // ─── Getters ─────────────────────────────────────────────────────────────────
  MangaLoadingState get loadingState => _loadingState;
  List<Manga> get mangaList => _filteredList;
  List<Manga> get allManga => _mangaList;
  MangaStats? get stats => _stats;
  String get searchQuery => _searchQuery;
  String get selectedGenre => _selectedGenre;
  String get selectedStatus => _selectedStatus;
  String get viewMode => _viewMode;
  String get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == MangaLoadingState.loading;
  bool get statsLoading => _statsLoading;

  List<Manga> get favoriteManga => _mangaList.where((m) => m.isFavorite).toList();
  int get totalCount => _mangaList.length;
  int get completedCount => _mangaList.where((m) => m.status == 'Hoàn thành').length;
  int get readingCount => _mangaList.where((m) => m.status == 'Đang tiến hành').length;

  // ─── Initialization ──────────────────────────────────────────────────────────
  Future<void> init() async {
    _viewMode = await _prefsService.getDefaultView();
    await loadManga();
  }

  // ─── Load All Manga ──────────────────────────────────────────────────────────
  Future<void> loadManga() async {
    _loadingState = MangaLoadingState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _mangaList = await _dbService.getAllManga();
      _applyFilters();
      _loadingState = MangaLoadingState.loaded;
    } catch (e) {
      _loadingState = MangaLoadingState.error;
      _errorMessage = 'Không thể tải dữ liệu: ${e.toString()}';
    }

    notifyListeners();
  }

  // ─── CRUD Operations ─────────────────────────────────────────────────────────

  /// CREATE: Thêm truyện mới
  Future<bool> addManga(Manga manga) async {
    try {
      final id = await _dbService.insertManga(manga);
      final newManga = manga.copyWith(id: id);
      _mangaList.insert(0, newManga);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể thêm truyện: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// UPDATE: Cập nhật thông tin truyện
  Future<bool> updateManga(Manga manga) async {
    try {
      await _dbService.updateManga(manga);
      final index = _mangaList.indexWhere((m) => m.id == manga.id);
      if (index != -1) {
        _mangaList[index] = manga.copyWith(updatedAt: DateTime.now());
        _applyFilters();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật truyện: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// DELETE: Xóa truyện
  Future<bool> deleteManga(int id) async {
    try {
      await _dbService.deleteManga(id);
      _mangaList.removeWhere((m) => m.id == id);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa truyện: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// TOGGLE FAVORITE
  Future<void> toggleFavorite(Manga manga) async {
    final newFavorite = !manga.isFavorite;
    await _dbService.toggleFavorite(manga.id!, newFavorite);
    final index = _mangaList.indexWhere((m) => m.id == manga.id);
    if (index != -1) {
      _mangaList[index] = manga.copyWith(isFavorite: newFavorite);
      _applyFilters();
      notifyListeners();
    }
  }

  /// UPDATE READ PROGRESS
  Future<void> updateReadProgress(Manga manga, int readChapters) async {
    await _dbService.updateReadProgress(manga.id!, readChapters);

    // Ghi lịch sử đọc
    if (readChapters > manga.readChapters) {
      await _dbService.addReadingHistory(ReadingHistory(
        mangaId: manga.id!,
        mangaTitle: manga.title,
        chapterNumber: readChapters,
        progress: manga.totalChapters > 0 ? readChapters / manga.totalChapters : 0,
      ));
    }

    final index = _mangaList.indexWhere((m) => m.id == manga.id);
    if (index != -1) {
      _mangaList[index] = manga.copyWith(readChapters: readChapters);
      _applyFilters();
      notifyListeners();
    }
  }

  // ─── Search & Filter ─────────────────────────────────────────────────────────
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByGenre(String genre) {
    _selectedGenre = genre;
    _applyFilters();
    notifyListeners();
  }

  void filterByStatus(String status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedGenre = '';
    _selectedStatus = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredList = _mangaList.where((manga) {
      bool matchesSearch = _searchQuery.isEmpty ||
          manga.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          manga.author.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesGenre =
          _selectedGenre.isEmpty || manga.genre == _selectedGenre;

      bool matchesStatus =
          _selectedStatus.isEmpty || manga.status == _selectedStatus;

      return matchesSearch && matchesGenre && matchesStatus;
    }).toList();
  }

  // ─── View Mode ───────────────────────────────────────────────────────────────
  Future<void> setViewMode(String mode) async {
    _viewMode = mode;
    await _prefsService.setDefaultView(mode);
    notifyListeners();
  }

  // ─── Statistics ──────────────────────────────────────────────────────────────
  Future<void> loadStats() async {
    _statsLoading = true;
    notifyListeners();
    try {
      _stats = await _dbService.getStats();
    } catch (e) {
      _errorMessage = 'Không thể tải thống kê';
    }
    _statsLoading = false;
    notifyListeners();
  }

  // ─── Get Single Manga ─────────────────────────────────────────────────────────
  Manga? getMangaById(int id) {
    try {
      return _mangaList.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
