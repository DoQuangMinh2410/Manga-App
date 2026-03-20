// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../providers/manga_provider.dart';
import '../widgets/app_widgets.dart';
import 'add_edit_screen.dart';
import 'chapter/chapter_list_screen.dart';

class DetailScreen extends StatefulWidget {
  final Manga manga;

  const DetailScreen({super.key, required this.manga});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late Manga _manga;
  late final AnimationController _animController;
  late final Animation<double> _contentAnim;
  bool _isUpdatingProgress = false;
  final TextEditingController _chapterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manga = widget.manga;
    _chapterCtrl.text = _manga.readChapters.toString();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _chapterCtrl.dispose();
    super.dispose();
  }

  // ─── Update progress ─────────────────────────────────────────────────────────
  Future<void> _showProgressDialog() async {
    final theme = Theme.of(context);
    _chapterCtrl.text = _manga.readChapters.toString();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cập nhật tiến trình',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn đang đọc đến chương nào?',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _chapterCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Chương đã đọc',
                suffixText: _manga.totalChapters > 0
                    ? '/ ${_manga.totalChapters}'
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(_chapterCtrl.text.trim()) ?? 0;
              Navigator.of(ctx).pop(val);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() => _isUpdatingProgress = true);
      final provider = context.read<MangaProvider>();
      await provider.updateReadProgress(_manga, result);
      // Refresh manga data
      final updated = provider.getMangaById(_manga.id!);
      if (updated != null && mounted) {
        setState(() {
          _manga = updated;
          _isUpdatingProgress = false;
        });
      }
    }
  }

  // ─── Navigate to Edit ─────────────────────────────────────────────────────────
  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(manga: _manga)),
    );

    if (result == true && mounted) {
      final provider = context.read<MangaProvider>();
      final updated = provider.getMangaById(_manga.id!);
      if (updated != null) {
        setState(() => _manga = updated);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin truyện'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ─── Delete ──────────────────────────────────────────────────────────────────
  Future<void> _deleteManga() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Xóa truyện',
      content:
          'Bạn có chắc chắn muốn xóa "${_manga.title}"?\nHành động này không thể hoàn tác.',
      confirmLabel: 'Xóa',
      cancelLabel: 'Hủy',
      icon: Icons.delete_forever_rounded,
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirmed == true && mounted) {
      final success =
          await context.read<MangaProvider>().deleteManga(_manga.id!);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─ Hero Cover App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // Toggle Favorite
              Consumer<MangaProvider>(
                builder: (_, provider, __) {
                  final current =
                      provider.getMangaById(_manga.id!) ?? _manga;
                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        current.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: current.isFavorite
                            ? const Color(0xFFFF6584)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () async {
                      await provider.toggleFavorite(current);
                      final updated = provider.getMangaById(_manga.id!);
                      if (updated != null && mounted) {
                        setState(() => _manga = updated);
                      }
                    },
                  );
                },
              ),
              // Edit
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 20),
                ),
                onPressed: _navigateToEdit,
              ),
              // Delete
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.white, size: 20),
                ),
                onPressed: _deleteManga,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Animation Cover
                  Hero(
                    tag: 'manga_cover_${_manga.id}',
                    child: MangaCoverImage(
                      coverUrl: _manga.coverUrl,
                      title: _manga.title,
                      width: double.infinity,
                      height: 280,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Title at bottom
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _manga.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8)
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _manga.author,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─ Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_contentAnim),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─ Quick Info Row ────────────────────────────────────
                      _buildInfoRow(),
                      const SizedBox(height: 24),

                      // ─ Reading Progress ──────────────────────────────────
                      _buildReadingProgress(theme),
                      const SizedBox(height: 24),

                      // ─ Description ───────────────────────────────────────
                      if (_manga.description.isNotEmpty) ...[
                        SectionHeader(title: 'Giới thiệu'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _manga.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.7,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ─ Details Grid ──────────────────────────────────────
                      SectionHeader(title: 'Thông tin chi tiết'),
                      const SizedBox(height: 12),
                      _buildDetailsGrid(theme),
                      const SizedBox(height: 32),

                      // ─ Action Buttons ─────────────────────────────────────
                      _buildActionButtons(theme),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        StatusBadge(status: _manga.status),
        _InfoChip(
          icon: Icons.category_outlined,
          label: _manga.genre,
          color: theme.colorScheme.secondary,
        ),
        if (_manga.rating > 0)
          _InfoChip(
            icon: Icons.star_rounded,
            label: '${_manga.rating.toStringAsFixed(1)} / 10',
            color: Colors.amber,
          ),
        if (_manga.publishYear != null)
          _InfoChip(
            icon: Icons.calendar_today_outlined,
            label: '${_manga.publishYear}',
            color: theme.colorScheme.tertiary,
          ),
      ],
    );
  }

  Widget _buildReadingProgress(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.12),
            theme.colorScheme.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tiến trình đọc',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                _manga.progressText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _manga.readProgress,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              color: theme.colorScheme.primary,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_manga.readProgress * 100).toStringAsFixed(1)}% hoàn thành',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (_isUpdatingProgress)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: _showProgressDialog,
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Cập nhật'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(ThemeData theme) {
    final items = [
      _DetailItem(
          icon: Icons.menu_book_outlined,
          label: 'Tổng chương',
          value: _manga.totalChapters > 0
              ? '${_manga.totalChapters} chương'
              : 'Chưa xác định'),
      _DetailItem(
          icon: Icons.bookmark_rounded,
          label: 'Đã đọc',
          value: '${_manga.readChapters} chương'),
      _DetailItem(
          icon: Icons.flag_outlined,
          label: 'Trạng thái',
          value: _manga.status),
      _DetailItem(
          icon: Icons.category_outlined,
          label: 'Thể loại',
          value: _manga.genre),
      if (_manga.publishYear != null)
        _DetailItem(
            icon: Icons.calendar_month_outlined,
            label: 'Năm xuất bản',
            value: '${_manga.publishYear}'),
      _DetailItem(
          icon: Icons.schedule_outlined,
          label: 'Ngày thêm',
          value: _formatDate(_manga.createdAt)),
      _DetailItem(
          icon: Icons.update_rounded,
          label: 'Cập nhật lần cuối',
          value: _formatDate(_manga.updatedAt)),
      _DetailItem(
          icon: Icons.favorite_rounded,
          label: 'Yêu thích',
          value: _manga.isFavorite ? 'Có ♥' : 'Chưa'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(item.icon,
                  size: 16,
                  color: theme.colorScheme.primary.withOpacity(0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // ─ Đọc truyện (Firebase Chapters) ──────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChapterListScreen(manga: _manga),
              ),
            ),
            icon: const Icon(Icons.auto_stories_rounded, size: 20),
            label: const Text(
              'Đọc Truyện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ─ Edit / Update / Delete ───────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigateToEdit,
                icon: const Icon(Icons.edit_rounded, size: 17),
                label: const Text('Chỉnh sửa'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showProgressDialog,
                icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                label: const Text('Cập nhật'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _deleteManga,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.all(13),
                minimumSize: Size.zero,
              ),
              child: const Icon(Icons.delete_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
