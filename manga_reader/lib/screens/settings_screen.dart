// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/manga_provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/preferences_service.dart';
import '../utils/constants.dart';
import '../widgets/app_widgets.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultView = AppConstants.viewGrid;
  double _fontSize = 16.0;
  final _prefsService = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final view = await _prefsService.getDefaultView();
    final size = await _prefsService.getReadingFontSize();
    if (mounted) {
      setState(() {
        _defaultView = view;
        _fontSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('Cài đặt'),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
      // ─ Account ───────────────────────────────────────────────────────
              _buildAccountSection(context),

              // ─ App Appearance ─────────────────────────────────────────────
              _buildSectionHeader(context, 'Giao diện', Icons.palette_outlined),
              _buildSettingCard([
                // Dark Mode
                _SettingTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Chế độ tối',
                  subtitle: themeProvider.isDarkMode
                      ? 'Đang bật chế độ tối'
                      : 'Đang dùng chế độ sáng',
                  trailing: Switch.adaptive(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: theme.colorScheme.primary,
                  ),
                ),

                const Divider(height: 1, indent: 56),

                // Default View
                _SettingTile(
                  icon: Icons.view_module_outlined,
                  title: 'Chế độ xem mặc định',
                  subtitle: _defaultView == AppConstants.viewGrid
                      ? 'Lưới (Grid)'
                      : 'Danh sách (List)',
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _defaultView,
                      items: const [
                        DropdownMenuItem(
                          value: AppConstants.viewGrid,
                          child: Text('Lưới', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.viewList,
                          child: Text('Danh sách',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (v) async {
                        if (v != null) {
                          setState(() => _defaultView = v);
                          await _prefsService.setDefaultView(v);
                          if (mounted) {
                            context.read<MangaProvider>().setViewMode(v);
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      isDense: true,
                    ),
                  ),
                ),
              ]),

              // ─ Reading ────────────────────────────────────────────────────
              _buildSectionHeader(
                  context, 'Đọc truyện', Icons.menu_book_outlined),
              _buildSettingCard([
                // Font Size
                _SettingTile(
                  icon: Icons.format_size_rounded,
                  title: 'Cỡ chữ đọc truyện',
                  subtitle: '${_fontSize.toStringAsFixed(0)}px',
                  trailing: null,
                  onTap: null,
                  expandedContent: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: _fontSize,
                          min: 12,
                          max: 24,
                          divisions: 6,
                          label: '${_fontSize.toStringAsFixed(0)}px',
                          onChanged: (v) async {
                            setState(() => _fontSize = v);
                            await _prefsService.setReadingFontSize(v);
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nhỏ (12px)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5))),
                            Text('Lớn (24px)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),

              // ─ Data ──────────────────────────────────────────────────────
              _buildSectionHeader(
                  context, 'Dữ liệu & Bộ nhớ', Icons.storage_outlined),
              _buildSettingCard([
                _SettingTile(
                  icon: Icons.refresh_rounded,
                  title: 'Làm mới danh sách',
                  subtitle: 'Tải lại dữ liệu từ database',
                  onTap: () async {
                    await context.read<MangaProvider>().loadManga();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã làm mới danh sách truyện'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                _SettingTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Xóa bộ nhớ đệm cài đặt',
                  subtitle: 'Đặt lại tất cả cài đặt về mặc định',
                  iconColor: theme.colorScheme.error,
                  titleColor: theme.colorScheme.error,
                  onTap: () async {
                    final confirm = await ConfirmationDialog.show(
                      context,
                      title: 'Đặt lại cài đặt',
                      content:
                          'Tất cả cài đặt sẽ được đặt lại về mặc định. Dữ liệu truyện sẽ không bị ảnh hưởng.',
                      confirmLabel: 'Đặt lại',
                      cancelLabel: 'Hủy',
                      icon: Icons.restore_rounded,
                      confirmColor: theme.colorScheme.error,
                    );
                    if (confirm == true && mounted) {
                      await _prefsService.clearAll();
                      context.read<ThemeProvider>().setDarkMode(false);
                      setState(() {
                        _defaultView = AppConstants.viewGrid;
                        _fontSize = 16.0;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã đặt lại cài đặt')),
                        );
                      }
                    }
                  },
                ),
              ]),

              // ─ About ─────────────────────────────────────────────────────
              _buildSectionHeader(
                  context, 'Về ứng dụng', Icons.info_outline_rounded),
              _buildSettingCard([
                _SettingTile(
                  icon: Icons.apps_rounded,
                  title: 'Tên ứng dụng',
                  subtitle: AppConstants.appName,
                ),
                const Divider(height: 1, indent: 56),
                _SettingTile(
                  icon: Icons.tag_rounded,
                  title: 'Phiên bản',
                  subtitle: 'v${AppConstants.appVersion}',
                ),
                const Divider(height: 1, indent: 56),
                _SettingTile(
                  icon: Icons.code_rounded,
                  title: 'Công nghệ',
                  subtitle: 'Flutter • Dart • SQLite • Provider',
                ),
                const Divider(height: 1, indent: 56),
                _SettingTile(
                  icon: Icons.school_outlined,
                  title: 'Mục đích',
                  subtitle: 'Đồ án môn học Flutter – CRUD App',
                ),
              ]),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<app_auth.AuthProvider>();

    if (auth.isLoggedIn && auth.user != null) {
      final user = auth.user!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Tài khoản', Icons.account_circle_outlined),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              children: [
                // User profile header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.15),
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.55),
                              ),
                            ),
                            if (user.isAdmin) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.amber.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 11),
                                    SizedBox(width: 4),
                                    Text(
                                      'Admin',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.amber,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // Logout
                _SettingTile(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  subtitle: 'Thoát khỏi tài khoản Firebase',
                  iconColor: theme.colorScheme.error,
                  titleColor: theme.colorScheme.error,
                  onTap: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: 'Đăng xuất',
                      content:
                          'Bạn có chắc muốn đăng xuất?\nDữ liệu cục bộ vẫn được giữ lại.',
                      confirmLabel: 'Đăng xuất',
                      cancelLabel: 'Hủy',
                      icon: Icons.logout_rounded,
                      confirmColor: theme.colorScheme.error,
                    );
                    if (confirmed == true && context.mounted) {
                      await context.read<app_auth.AuthProvider>().logout();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Not logged in
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Tài khoản Firebase', Icons.cloud_outlined),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.25)),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa đăng nhập',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đăng nhập để đọc chapter trực tuyến\nvà đồng bộ tiến trình đọc',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Đăng nhập / Đăng ký'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ─── Setting Tile ─────────────────────────────────────────────────────────────
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? expandedContent;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.expandedContent,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.primary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: iconColor ?? theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.55),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (onTap != null && trailing == null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
              ],
            ),
          ),
        ),
        if (expandedContent != null) expandedContent!,
      ],
    );
  }
}
