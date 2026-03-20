// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/manga_provider.dart';
import '../providers/theme_provider.dart';
import '../models/manga.dart';
import '../utils/constants.dart';
import '../widgets/manga_card.dart';
import '../widgets/app_widgets.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _fabController;
  late final Animation<double> _fabAnimation;
  bool _isSearching = false;

  // Filter chips
  String? _activeGenreFilter;
  String? _activeStatusFilter;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // ─── Navigate to Add/Edit ─────────────────────────────────────────────────────
  Future<void> _navigateToAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditScreen()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Thêm truyện thành công!'),
            ],
          ),
          backgroundColor: const Color(0xFF43C6AC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ─── Navigate to Detail ───────────────────────────────────────────────────────
  void _navigateToDetail(Manga manga) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => DetailScreen(manga: manga),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ─── Delete Manga ─────────────────────────────────────────────────────────────
  Future<void> _deleteManga(Manga manga) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Xóa truyện',
      content:
          'Bạn có chắc chắn muốn xóa "${manga.title}"?\nHành động này không thể hoàn tác.',
      confirmLabel: 'Xóa',
      cancelLabel: 'Hủy',
      icon: Icons.delete_forever_rounded,
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirmed == true && mounted) {
      final provider = context.read<MangaProvider>();
      final success = await provider.deleteManga(manga.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa truyện'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: _navigateToAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm truyện',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildFavoritesTab();
      case 2:
        return const StatisticsScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 2) {
            context.read<MangaProvider>().loadStats();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Thư viện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HOME TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildHomeTab() {
    return Consumer<MangaProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            // ─ App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 130,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: _isSearching
                    ? _buildSearchField(provider)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MangaVerse',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            '${provider.totalCount} truyện • ${provider.readingCount} đang đọc',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.55),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                collapseMode: CollapseMode.pin,
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        provider.search('');
                      }
                    });
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isSearching
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      key: ValueKey(_isSearching),
                    ),
                  ),
                  tooltip: _isSearching ? 'Đóng tìm kiếm' : 'Tìm kiếm',
                ),
                Consumer<MangaProvider>(
                  builder: (_, p, __) => IconButton(
                    onPressed: () async {
                      final newMode = p.viewMode == AppConstants.viewGrid
                          ? AppConstants.viewList
                          : AppConstants.viewGrid;
                      await p.setViewMode(newMode);
                    },
                    icon: Icon(
                      p.viewMode == AppConstants.viewGrid
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                    ),
                    tooltip: 'Chuyển chế độ xem',
                  ),
                ),
              ],
            ),

            // ─ Filter Chips ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildFilterChips(provider),
            ),

            // ─ Content ───────────────────────────────────────────────────────
            if (provider.isLoading)
              const SliverFillRemaining(
                child: AppLoadingIndicator(message: 'Đang tải danh sách...'),
              )
            else if (provider.mangaList.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  title: provider.searchQuery.isNotEmpty ||
                          provider.selectedGenre.isNotEmpty
                      ? 'Không tìm thấy kết quả'
                      : 'Thư viện trống',
                  subtitle: provider.searchQuery.isNotEmpty
                      ? 'Thử từ khóa khác hoặc xóa bộ lọc'
                      : 'Bắt đầu thêm truyện tranh\nyêu thích của bạn!',
                  icon: Icons.menu_book_rounded,
                  actionLabel: provider.searchQuery.isEmpty
                      ? 'Thêm truyện đầu tiên'
                      : null,
                  onAction:
                      provider.searchQuery.isEmpty ? _navigateToAdd : null,
                ),
              )
            else
              provider.viewMode == AppConstants.viewGrid
                  ? _buildGridView(provider)
                  : _buildListView(provider),

            // Padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(MangaProvider provider) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Tìm tên truyện, tác giả...',
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (q) => provider.search(q),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildFilterChips(MangaProvider provider) {
    final theme = Theme.of(context);
    final genres = AppConstants.mangaGenres;
    final statuses = AppConstants.mangaStatuses;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          // Clear all button
          if (provider.selectedGenre.isNotEmpty ||
              provider.selectedStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_rounded, size: 14),
                    SizedBox(width: 4),
                    Text('Xóa lọc'),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    _activeGenreFilter = null;
                    _activeStatusFilter = null;
                  });
                  provider.clearFilters();
                },
                backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Status filters
          ...statuses.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s),
                  selected: provider.selectedStatus == s,
                  onSelected: (selected) {
                    setState(() => _activeStatusFilter = selected ? s : null);
                    provider.filterByStatus(selected ? s : '');
                  },
                  showCheckmark: false,
                  selectedColor:
                      theme.colorScheme.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: provider.selectedStatus == s
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              )),

          const SizedBox(width: 4),
          VerticalDivider(
            color: theme.dividerColor,
            width: 16,
            thickness: 1,
          ),
          const SizedBox(width: 4),

          // Genre filters
          ...genres.map((g) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(g),
                  selected: provider.selectedGenre == g,
                  onSelected: (selected) {
                    setState(() => _activeGenreFilter = selected ? g : null);
                    provider.filterByGenre(selected ? g : '');
                  },
                  showCheckmark: false,
                  selectedColor:
                      theme.colorScheme.secondary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: provider.selectedGenre == g
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGridView(MangaProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final manga = provider.mangaList[index];
            return MangaGridCard(
              manga: manga,
              onTap: () => _navigateToDetail(manga),
              onFavorite: () => provider.toggleFavorite(manga),
              onDelete: () => _deleteManga(manga),
            );
          },
          childCount: provider.mangaList.length,
        ),
      ),
    );
  }

  Widget _buildListView(MangaProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final manga = provider.mangaList[index];
            return MangaListCard(
              manga: manga,
              onTap: () => _navigateToDetail(manga),
              onFavorite: () => provider.toggleFavorite(manga),
              onDelete: () => _deleteManga(manga),
            );
          },
          childCount: provider.mangaList.length,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FAVORITES TAB
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildFavoritesTab() {
    return Consumer<MangaProvider>(
      builder: (context, provider, _) {
        final favorites = provider.favoriteManga;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Yêu thích'),
            ),
            if (favorites.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  title: 'Chưa có truyện yêu thích',
                  subtitle: 'Nhấn vào biểu tượng ♡\ntrên truyện để thêm vào đây',
                  icon: Icons.favorite_border_rounded,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => MangaGridCard(
                      manga: favorites[i],
                      onTap: () => _navigateToDetail(favorites[i]),
                      onFavorite: () =>
                          provider.toggleFavorite(favorites[i]),
                      onDelete: () => _deleteManga(favorites[i]),
                    ),
                    childCount: favorites.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }
}
