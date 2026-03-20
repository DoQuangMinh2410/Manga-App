// lib/providers/chapter_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../services/firebase_service.dart';

enum ChapterLoadState { idle, loading, loaded, error }

class ChapterProvider extends ChangeNotifier {
  final FirebaseService _service;
  ChapterProvider(this._service);

  final Map<String, List<Chapter>> _chaptersByManga = {};
  ChapterLoadState _state = ChapterLoadState.idle;
  String _currentMangaId = '';
  String _errorMessage = '';
  int _uploadProgress = 0;
  int _uploadTotal = 0;
  bool _isUploading = false;

  // ─── Getters ─────────────────────────────────────────────────────────────
  ChapterLoadState get state => _state;
  bool get isLoading => _state == ChapterLoadState.loading;
  bool get isUploading => _isUploading;
  int get uploadProgress => _uploadProgress;
  int get uploadTotal => _uploadTotal;
  String get errorMessage => _errorMessage;

  List<Chapter> getChaptersForManga(String mangaId) =>
      _chaptersByManga[mangaId] ?? [];

  double get uploadPercent =>
      _uploadTotal > 0 ? _uploadProgress / _uploadTotal : 0;

  // ─── Load Chapters ────────────────────────────────────────────────────────
  Future<void> loadChapters(String mangaId) async {
    if (_currentMangaId == mangaId &&
        _chaptersByManga.containsKey(mangaId) &&
        _state == ChapterLoadState.loaded) return;

    _currentMangaId = mangaId;
    _state = ChapterLoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final chapters = await _service.getChapters(mangaId);
      _chaptersByManga[mangaId] = chapters;
      _state = ChapterLoadState.loaded;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách chapter: ${e.toString()}';
      _state = ChapterLoadState.error;
    }
    notifyListeners();
  }

  /// Refresh (force reload)
  Future<void> refreshChapters(String mangaId) async {
    _chaptersByManga.remove(mangaId);
    await loadChapters(mangaId);
  }

  // ─── Add Chapter + Upload Images ─────────────────────────────────────────
  Future<bool> addChapterWithImages({
    required String mangaId,
    required String mangaTitle,
    required int chapterNumber,
    required String chapterTitle,
    required List<File> imageFiles,
  }) async {
    if (imageFiles.isEmpty) {
      _errorMessage = 'Vui lòng chọn ít nhất 1 ảnh';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _uploadProgress = 0;
    _uploadTotal = imageFiles.length;
    _errorMessage = '';
    notifyListeners();

    try {
      // Upload tất cả ảnh lên Firebase Storage
      final imageUrls = await _service.uploadChapterImages(
        imageFiles: imageFiles,
        mangaId: mangaId,
        chapterNumber: chapterNumber,
        onProgress: (current, total) {
          _uploadProgress = current;
          notifyListeners();
        },
      );

      // Tạo Chapter document trên Firestore
      final chapter = Chapter(
        mangaId: mangaId,
        mangaTitle: mangaTitle,
        chapterNumber: chapterNumber,
        title: chapterTitle,
        imageUrls: imageUrls,
        pageCount: imageUrls.length,
      );

      final docId = await _service.addChapter(chapter);
      final savedChapter = chapter.copyWith(id: docId);

      // Cập nhật local cache
      _chaptersByManga[mangaId] = [
        ...(_chaptersByManga[mangaId] ?? []),
        savedChapter,
      ]..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));

      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Upload thất bại: ${e.toString()}';
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Delete Chapter ───────────────────────────────────────────────────────
  Future<bool> deleteChapter(String mangaId, Chapter chapter) async {
    try {
      await _service.deleteChapter(
        chapter.id!,
        imageUrls: chapter.imageUrls,
      );
      _chaptersByManga[mangaId]?.removeWhere((c) => c.id == chapter.id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Xóa chapter thất bại';
      notifyListeners();
      return false;
    }
  }

  // ─── Save Read State ──────────────────────────────────────────────────────
  Future<void> saveReadState({
    required String userId,
    required String chapterId,
    required String mangaId,
    required int lastPage,
    required bool isCompleted,
  }) async {
    try {
      await _service.saveReadState(ChapterReadState(
        userId: userId,
        chapterId: chapterId,
        mangaId: mangaId,
        lastPage: lastPage,
        isCompleted: isCompleted,
      ));
    } catch (_) {}
  }

  Future<ChapterReadState?> getReadState(
          String userId, String chapterId) =>
      _service.getReadState(userId, chapterId);
}
