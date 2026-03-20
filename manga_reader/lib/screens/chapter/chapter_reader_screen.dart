// lib/screens/chapter/chapter_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../../models/chapter.dart';
import '../../models/manga.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chapter_provider.dart';

class ChapterReaderScreen extends StatefulWidget {
  final Chapter chapter;
  final Manga manga;

  const ChapterReaderScreen({
    super.key,
    required this.chapter,
    required this.manga,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageCtrl;
  int _currentPage = 0;
  bool _showOverlay = true;
  bool _isVerticalMode = false; // Chế độ cuộn dọc (webtoon) hay ngang
  late final AnimationController _overlayAnim;
  late final Animation<double> _overlayFade;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _overlayAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _overlayFade = CurvedAnimation(parent: _overlayAnim, curve: Curves.easeOut);

    // Toàn màn hình khi đọc
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Khôi phục tiến trình đọc
    _restoreReadState();
  }

  Future<void> _restoreReadState() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null || widget.chapter.id == null) return;
    final state = await context
        .read<ChapterProvider>()
        .getReadState(userId, widget.chapter.id!);
    if (state != null && state.lastPage > 0 && mounted) {
      setState(() => _currentPage = state.lastPage);
      _pageCtrl.jumpToPage(state.lastPage);
    }
  }

  @override
  void dispose() {
    // Lưu tiến trình khi thoát
    _saveReadState();
    // Khôi phục system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageCtrl.dispose();
    _overlayAnim.dispose();
    super.dispose();
  }

  Future<void> _saveReadState() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null || widget.chapter.id == null) return;
    final isCompleted =
        _currentPage >= widget.chapter.imageUrls.length - 1;
    await context.read<ChapterProvider>().saveReadState(
          userId: userId,
          chapterId: widget.chapter.id!,
          mangaId: widget.manga.id.toString(),
          lastPage: _currentPage,
          isCompleted: isCompleted,
        );
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) {
      _overlayAnim.forward();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      _overlayAnim.reverse();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.chapter.imageUrls;
    final theme = Theme.of(context);

    if (pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.chapter.displayTitle)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Chương này chưa có ảnh'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─ Reader Content ────────────────────────────────────────────────
          GestureDetector(
            onTap: _toggleOverlay,
            child: _isVerticalMode
                ? _buildVerticalReader(pages)
                : _buildHorizontalReader(pages),
          ),

          // ─ Top Overlay ───────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _overlayFade,
              child: _showOverlay
                  ? _buildTopBar(theme)
                  : const SizedBox.shrink(),
            ),
          ),

          // ─ Bottom Overlay ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _overlayFade,
              child: _showOverlay
                  ? _buildBottomBar(pages, theme)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Horizontal Reader (Manga style - lật trang) ─────────────────────────
  Widget _buildHorizontalReader(List<String> pages) {
    return PhotoViewGallery.builder(
      pageController: _pageCtrl,
      itemCount: pages.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(pages[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          heroAttributes:
              PhotoViewHeroAttributes(tag: 'page_${widget.chapter.id}_$index'),
          errorBuilder: (_, __, ___) => _buildPageError(index),
        );
      },
      loadingBuilder: (_, event) => _buildPageLoading(event),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      scrollPhysics: const ClampingScrollPhysics(),
    );
  }

  // ─── Vertical Reader (Webtoon style - cuộn dọc) ──────────────────────────
  Widget _buildVerticalReader(List<String> pages) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Có thể track position để cập nhật page indicator
        return false;
      },
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        itemCount: pages.length,
        itemBuilder: (_, index) {
          return GestureDetector(
            onTap: _toggleOverlay,
            child: CachedNetworkImage(
              imageUrl: pages[index],
              fit: BoxFit.fitWidth,
              width: double.infinity,
              placeholder: (_, __) => _buildPageLoadingVertical(),
              errorWidget: (_, __, ___) => _buildPageError(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageLoading(ImageChunkEvent? event) {
    final progress = event?.expectedTotalBytes != null
        ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
        : null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            color: Colors.white54,
            strokeWidth: 3,
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageLoadingVertical() {
    return Container(
      color: const Color(0xFF1A1A1A),
      height: 400,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
      ),
    );
  }

  Widget _buildPageError(int index) {
    return Container(
      color: const Color(0xFF1A1A1A),
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_rounded,
                color: Colors.white30, size: 48),
            const SizedBox(height: 12),
            Text(
              'Lỗi tải trang ${index + 1}',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.manga.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.chapter.displayTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Toggle mode
              IconButton(
                onPressed: () =>
                    setState(() => _isVerticalMode = !_isVerticalMode),
                icon: Icon(
                  _isVerticalMode
                      ? Icons.swap_horiz_rounded
                      : Icons.swap_vert_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
                tooltip: _isVerticalMode
                    ? 'Chuyển sang lật trang'
                    : 'Chuyển sang cuộn dọc',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────
  Widget _buildBottomBar(List<String> pages, ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page indicator
              if (!_isVerticalMode) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0
                          ? () {
                              _pageCtrl.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.navigate_before_rounded,
                          color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${pages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < pages.length - 1
                          ? () {
                              _pageCtrl.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.navigate_next_rounded,
                          color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Progress Slider
              if (!_isVerticalMode)
                SliderTheme(
                  data: SliderThemeData(
                    thumbColor: Colors.white,
                    activeTrackColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _currentPage.toDouble(),
                    min: 0,
                    max: (pages.length - 1).toDouble(),
                    divisions: pages.length > 1 ? pages.length - 1 : 1,
                    onChanged: (v) {
                      final page = v.toInt();
                      setState(() => _currentPage = page);
                      _pageCtrl.jumpToPage(page);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
