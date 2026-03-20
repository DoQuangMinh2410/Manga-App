// lib/screens/add_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../providers/manga_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_widgets.dart';

class AddEditScreen extends StatefulWidget {
  final Manga? manga; // null = thêm mới, non-null = chỉnh sửa

  const AddEditScreen({super.key, this.manga});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  bool _isSaving = false;

  // ─── Form Controllers ────────────────────────────────────────────────────────
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _coverUrlCtrl;
  late final TextEditingController _totalChaptersCtrl;
  late final TextEditingController _readChaptersCtrl;
  late final TextEditingController _ratingCtrl;
  late final TextEditingController _publishYearCtrl;

  // ─── Dropdown Values ──────────────────────────────────────────────────────────
  String _selectedGenre = AppConstants.mangaGenres.first;
  String _selectedStatus = AppConstants.mangaStatuses.first;
  bool _isFavorite = false;

  bool get isEditing => widget.manga != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Pre-fill nếu chỉnh sửa
    final m = widget.manga;
    _titleCtrl = TextEditingController(text: m?.title ?? '');
    _authorCtrl = TextEditingController(text: m?.author ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _coverUrlCtrl = TextEditingController(text: m?.coverUrl ?? '');
    _totalChaptersCtrl =
        TextEditingController(text: m?.totalChapters.toString() ?? '0');
    _readChaptersCtrl =
        TextEditingController(text: m?.readChapters.toString() ?? '0');
    _ratingCtrl = TextEditingController(
        text: m != null && m.rating > 0 ? m.rating.toString() : '');
    _publishYearCtrl = TextEditingController(
        text: m?.publishYear?.toString() ?? '');

    if (m != null) {
      _selectedGenre = m.genre;
      _selectedStatus = m.status;
      _isFavorite = m.isFavorite;
    }

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    _coverUrlCtrl.dispose();
    _totalChaptersCtrl.dispose();
    _readChaptersCtrl.dispose();
    _ratingCtrl.dispose();
    _publishYearCtrl.dispose();
    super.dispose();
  }

  // ─── Submit Form ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll to first error
      return;
    }

    setState(() => _isSaving = true);

    final totalCh = int.tryParse(_totalChaptersCtrl.text.trim()) ?? 0;
    final readCh = int.tryParse(_readChaptersCtrl.text.trim()) ?? 0;
    final rating = double.tryParse(_ratingCtrl.text.trim()) ?? 0.0;
    final year = int.tryParse(_publishYearCtrl.text.trim());

    final provider = context.read<MangaProvider>();
    bool success;

    if (isEditing) {
      final updated = widget.manga!.copyWith(
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        genre: _selectedGenre,
        status: _selectedStatus,
        description: _descCtrl.text.trim(),
        coverUrl: _coverUrlCtrl.text.trim(),
        totalChapters: totalCh,
        readChapters: readCh.clamp(0, totalCh),
        rating: rating,
        publishYear: year,
        isFavorite: _isFavorite,
      );
      success = await provider.updateManga(updated);
    } else {
      final manga = Manga(
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        genre: _selectedGenre,
        status: _selectedStatus,
        description: _descCtrl.text.trim(),
        coverUrl: _coverUrlCtrl.text.trim(),
        totalChapters: totalCh,
        readChapters: readCh.clamp(0, totalCh),
        rating: rating,
        publishYear: year,
        isFavorite: _isFavorite,
      );
      success = await provider.addManga(manga);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isEditing ? 'Cập nhật thất bại!' : 'Thêm truyện thất bại!'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa truyện' : 'Thêm truyện mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Favorite toggle trong app bar
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? const Color(0xFFFF6584) : null,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
            tooltip: 'Yêu thích',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ─ Cover Preview ───────────────────────────────────────────────
              _buildCoverPreview(),
              const SizedBox(height: 28),

              // ─ Thông tin cơ bản ────────────────────────────────────────────
              _buildSectionTitle('Thông tin cơ bản', Icons.info_outline_rounded),
              const SizedBox(height: 14),

              // Tên truyện
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên truyện *',
                  hintText: 'Nhập tên truyện tranh',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: Validators.title,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Tác giả
              TextFormField(
                controller: _authorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tác giả *',
                  hintText: 'Tên tác giả',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: Validators.author,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Thể loại + Trạng thái (2 cột)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGenre,
                      decoration: const InputDecoration(
                        labelText: 'Thể loại *',
                        prefixIcon: Icon(Icons.category_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      isExpanded: true,
                      items: AppConstants.mangaGenres
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedGenre = v!),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Vui lòng chọn thể loại' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái *',
                        prefixIcon: Icon(Icons.flag_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      isExpanded: true,
                      items: AppConstants.mangaStatuses
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mô tả
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Tóm tắt nội dung truyện...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.notes_rounded),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 2000,
                validator: Validators.description,
                textInputAction: TextInputAction.newline,
              ),

              const SizedBox(height: 24),

              // ─ Thông tin đọc ───────────────────────────────────────────────
              _buildSectionTitle('Tiến trình đọc', Icons.auto_stories_rounded),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalChaptersCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tổng số chương',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: Validators.chapters,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _readChaptersCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Đã đọc đến chương',
                        prefixIcon: Icon(Icons.bookmark_outline_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final err = Validators.chapters(v);
                        if (err != null) return err;
                        final total = int.tryParse(_totalChaptersCtrl.text) ?? 0;
                        final read = int.tryParse(v ?? '0') ?? 0;
                        if (total > 0 && read > total) {
                          return 'Vượt tổng số chương';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─ Thông tin thêm ──────────────────────────────────────────────
              _buildSectionTitle('Thông tin bổ sung', Icons.more_horiz_rounded),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ratingCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Đánh giá (0-10)',
                        hintText: 'VD: 8.5',
                        prefixIcon: Icon(Icons.star_outline_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.rating,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _publishYearCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Năm xuất bản',
                        hintText: 'VD: 2020',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: Validators.year,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // URL ảnh bìa
              TextFormField(
                controller: _coverUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL ảnh bìa',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                keyboardType: TextInputType.url,
                validator: Validators.coverUrl,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}), // Update preview
              ),

              const SizedBox(height: 36),

              // ─ Submit Button ───────────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isEditing
                          ? Icons.save_rounded
                          : Icons.add_circle_rounded),
                  label: Text(
                    _isSaving
                        ? (isEditing ? 'Đang lưu...' : 'Đang thêm...')
                        : (isEditing ? 'Lưu thay đổi' : 'Thêm truyện'),
                  ),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Hủy thay đổi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPreview() {
    final url = _coverUrlCtrl.text.trim();
    return Center(
      child: Column(
        children: [
          MangaCoverImage(
            coverUrl: url,
            title: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : '?',
            width: 110,
            height: 148,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(height: 8),
          Text(
            'Ảnh bìa xem trước',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
      ],
    );
  }
}
