// lib/screens/chapter/add_chapter_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/manga.dart';
import '../../providers/chapter_provider.dart';

class AddChapterScreen extends StatefulWidget {
  final Manga manga;
  const AddChapterScreen({super.key, required this.manga});

  @override
  State<AddChapterScreen> createState() => _AddChapterScreenState();
}

class _AddChapterScreenState extends State<AddChapterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterNumCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _chapterNumCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  // ─── Pick images from gallery ─────────────────────────────────────────────
  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: 100,
      );
      if (picked.isNotEmpty) {
        final files = picked.map((xf) => File(xf.path)).toList();
        setState(() {
          _selectedImages = [..._selectedImages, ...files];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  // ─── Remove a selected image ──────────────────────────────────────────────
  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ─── Reorder images ───────────────────────────────────────────────────────
  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ảnh cho chương'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<ChapterProvider>();
    final success = await provider.addChapterWithImages(
      mangaId: widget.manga.id.toString(),
      mangaTitle: widget.manga.title,
      chapterNumber: int.parse(_chapterNumCtrl.text.trim()),
      chapterTitle: _titleCtrl.text.trim().isEmpty
          ? 'Chương ${_chapterNumCtrl.text.trim()}'
          : _titleCtrl.text.trim(),
      imageFiles: _selectedImages,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                  'Upload chương ${_chapterNumCtrl.text} thành công!'),
            ]),
            backgroundColor: const Color(0xFF43C6AC),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage.isNotEmpty
                ? provider.errorMessage
                : 'Upload thất bại. Thử lại sau.'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Chương Mới',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              widget.manga.title,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.55)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Consumer<ChapterProvider>(
        builder: (_, provider, __) {
          // Overlay khi đang upload
          if (provider.isUploading) {
            return _buildUploadProgress(provider, theme);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ─ Chapter Info ──────────────────────────────────────────
                _buildSectionTitle('Thông tin chương', theme),
                const SizedBox(height: 14),

                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _chapterNumCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Số chương *',
                          hintText: '1',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Bắt buộc';
                          }
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1) return 'Không hợp lệ';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _titleCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề chương',
                          hintText: 'VD: Cuộc gặp gỡ định mệnh',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─ Image Selection ───────────────────────────────────────
                _buildSectionTitle('Ảnh trang truyện', theme),
                const SizedBox(height: 14),

                // Image count & actions
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library_rounded,
                                color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedImages.length} ảnh đã chọn',
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_rounded,
                          size: 18),
                      label: const Text('Chọn ảnh'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ─ Instructions ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.amber.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giữ và kéo để sắp xếp lại thứ tự trang. '
                          'Ảnh sẽ được upload lên Firebase Storage.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade700, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─ Image Grid (Reorderable) ───────────────────────────────
                if (_selectedImages.isNotEmpty) ...[
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: _reorderImages,
                    itemCount: _selectedImages.length,
                    itemBuilder: (_, index) {
                      return _ImageListTile(
                        key: ValueKey(_selectedImages[index].path),
                        file: _selectedImages[index],
                        index: index,
                        onRemove: () => _removeImage(index),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_selectedImages.isEmpty)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.4),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 48,
                              color: theme.colorScheme.primary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'Nhấn để chọn ảnh từ thư viện',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hỗ trợ JPG, PNG · Tối đa 100 ảnh',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // ─ Submit Button ──────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      _isSaving
                          ? 'Đang upload...'
                          : 'Upload ${_selectedImages.length} ảnh',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadProgress(ChapterProvider provider, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated upload icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: provider.uploadPercent),
              duration: const Duration(milliseconds: 300),
              builder: (_, value, __) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.12),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${(value * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Đang upload ảnh...',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Text(
              '${provider.uploadProgress} / ${provider.uploadTotal} ảnh',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Text(
                    'Vui lòng không thoát khỏi màn hình này',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.chevron_right_rounded,
            size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
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

// ─── Image List Tile ──────────────────────────────────────────────────────────
class _ImageListTile extends StatelessWidget {
  final File file;
  final int index;
  final VoidCallback onRemove;

  const _ImageListTile({
    super.key,
    required this.file,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(Icons.drag_handle_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.35), size: 22),
          ),

          // Page number
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: 50,
              height: 65,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.path.split('/').last,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: file.length(),
                  builder: (_, snap) => Text(
                    snap.hasData
                        ? '${(snap.data! / 1024).toStringAsFixed(1)} KB'
                        : '...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded,
                color: theme.colorScheme.error, size: 20),
            tooltip: 'Xóa',
          ),
        ],
      ),
    );
  }
}
