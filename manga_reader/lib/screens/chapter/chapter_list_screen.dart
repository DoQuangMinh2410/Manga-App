// lib/screens/chapter/chapter_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chapter.dart';
import '../../models/manga.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chapter_provider.dart';
import '../../widgets/app_widgets.dart';
import 'chapter_reader_screen.dart';
import 'add_chapter_screen.dart';

class ChapterListScreen extends StatefulWidget {
  final Manga manga;
  const ChapterListScreen({super.key, required this.manga});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ChapterProvider>()
          .loadChapters(widget.manga.id.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.manga.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Danh sách chương',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          // Nút refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context
                .read<ChapterProvider>()
                .refreshChapters(widget.manga.id.toString()),
            tooltip: 'Làm mới',
          ),
          // Nút thêm chapter (chỉ admin)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              onPressed: _navigateToAddChapter,
              tooltip: 'Thêm chương mới',
            ),
        ],
      ),
      body: Consumer<ChapterProvider>(
        builder: (context, provider, _) {
          final chapters =
              provider.getChaptersForManga(widget.manga.id.toString());

          if (provider.isLoading) {
            return const AppLoadingIndicator(message: 'Đang tải danh sách chương...');
          }

          if (provider.state == ChapterLoadState.error) {
            return _buildError(provider.errorMessage, context);
          }

          if (chapters.isEmpty) {
            return EmptyStateWidget(
              title: 'Chưa có chương nào',
              subtitle: isAdmin
                  ? 'Nhấn nút + để thêm chương mới'
                  : 'Chương sẽ được cập nhật sớm.\nHãy quay lại sau!',
              icon: Icons.auto_stories_rounded,
              actionLabel: isAdmin ? 'Thêm chương đầu tiên' : null,
              onAction: isAdmin ? _navigateToAddChapter : null,
            );
          }

          return _buildChapterList(chapters, provider, context);
        },
      ),
      // FAB thêm chapter (admin)
      floatingActionButton: context.watch<AuthProvider>().isAdmin
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddChapter,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Upload Chương',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildChapterList(
      List<Chapter> chapters, ChapterProvider provider, BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: chapters.length,
      itemBuilder: (_, i) {
        final chapter = chapters[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ChapterTile(
            chapter: chapter,
            mangaTitle: widget.manga.title,
            isAdmin: isAdmin,
            userId: userId,
            onTap: () => _openChapter(chapter),
            onDelete: isAdmin
                ? () => _deleteChapter(chapter, provider)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildError(String message, BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64,
                color: theme.colorScheme.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<ChapterProvider>()
                  .refreshChapters(widget.manga.id.toString()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  void _openChapter(Chapter chapter) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => ChapterReaderScreen(
          chapter: chapter,
          manga: widget.manga,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToAddChapter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddChapterScreen(manga: widget.manga),
      ),
    ).then((_) => context
        .read<ChapterProvider>()
        .refreshChapters(widget.manga.id.toString()));
  }

  Future<void> _deleteChapter(
      Chapter chapter, ChapterProvider provider) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Xóa chương',
      content:
          'Xóa "${chapter.displayTitle}"?\nTất cả ảnh của chương này cũng sẽ bị xóa.',
      confirmLabel: 'Xóa',
      cancelLabel: 'Hủy',
      icon: Icons.delete_forever_rounded,
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed == true && mounted) {
      await provider.deleteChapter(widget.manga.id.toString(), chapter);
    }
  }
}

// ─── Chapter Tile Widget ──────────────────────────────────────────────────────
class _ChapterTile extends StatefulWidget {
  final Chapter chapter;
  final String mangaTitle;
  final bool isAdmin;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ChapterTile({
    required this.chapter,
    required this.mangaTitle,
    required this.isAdmin,
    required this.userId,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<_ChapterTile> {
  bool _isRead = false;

  @override
  void initState() {
    super.initState();
    _checkReadState();
  }

  Future<void> _checkReadState() async {
    if (widget.userId.isEmpty || widget.chapter.id == null) return;
    final state = await context
        .read<ChapterProvider>()
        .getReadState(widget.userId, widget.chapter.id!);
    if (state != null && mounted) {
      setState(() => _isRead = state.isCompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapter = widget.chapter;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: _isRead
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chapter Number Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRead
                      ? [
                          theme.colorScheme.primary.withOpacity(0.7),
                          theme.colorScheme.secondary.withOpacity(0.7),
                        ]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${chapter.chapterNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chapter.displayTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isRead
                                ? theme.colorScheme.onSurface.withOpacity(0.55)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (_isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 11,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                'Đã đọc',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 13,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.45)),
                      const SizedBox(width: 4),
                      Text(
                        '${chapter.imageUrls.length} trang',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                if (widget.isAdmin && widget.onDelete != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.error.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
