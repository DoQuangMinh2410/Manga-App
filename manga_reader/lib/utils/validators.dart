// lib/utils/validators.dart

class Validators {
  /// Kiểm tra trường không được rỗng
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    return null;
  }

  /// Kiểm tra tiêu đề truyện
  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tên truyện không được để trống';
    }
    if (value.trim().length < 2) {
      return 'Tên truyện phải có ít nhất 2 ký tự';
    }
    if (value.trim().length > 200) {
      return 'Tên truyện không được vượt quá 200 ký tự';
    }
    return null;
  }

  /// Kiểm tra tên tác giả
  static String? author(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tên tác giả không được để trống';
    }
    if (value.trim().length < 2) {
      return 'Tên tác giả phải có ít nhất 2 ký tự';
    }
    return null;
  }

  /// Kiểm tra số chương (phải là số nguyên dương)
  static String? chapters(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Số chương không được để trống';
    }
    final num = int.tryParse(value.trim());
    if (num == null) {
      return 'Số chương phải là số nguyên';
    }
    if (num < 0) {
      return 'Số chương không được âm';
    }
    if (num > 10000) {
      return 'Số chương không hợp lệ (tối đa 10000)';
    }
    return null;
  }

  /// Kiểm tra đánh giá (0.0 - 10.0)
  static String? rating(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Rating là tùy chọn
    }
    final num = double.tryParse(value.trim());
    if (num == null) {
      return 'Đánh giá phải là số';
    }
    if (num < 0 || num > 10) {
      return 'Đánh giá phải từ 0 đến 10';
    }
    return null;
  }

  /// Kiểm tra URL ảnh bìa (tùy chọn)
  static String? coverUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Không bắt buộc
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'URL ảnh bìa không hợp lệ (phải bắt đầu bằng http/https)';
    }
    return null;
  }

  /// Kiểm tra mô tả
  static String? description(String? value) {
    if (value != null && value.trim().length > 2000) {
      return 'Mô tả không được vượt quá 2000 ký tự';
    }
    return null;
  }

  /// Kiểm tra năm xuất bản
  static String? year(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Tùy chọn
    }
    final num = int.tryParse(value.trim());
    if (num == null) {
      return 'Năm xuất bản phải là số nguyên';
    }
    if (num < 1900 || num > DateTime.now().year + 1) {
      return 'Năm xuất bản không hợp lệ';
    }
    return null;
  }
}
