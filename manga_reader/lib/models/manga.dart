// lib/models/manga.dart

class Manga {
  final int? id;
  final String title;
  final String author;
  final String genre;
  final String status;
  final String description;
  final String coverUrl;
  final int totalChapters;
  final int readChapters;
  final double rating;
  final int? publishYear;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Manga({
    this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.description = '',
    this.coverUrl = '',
    this.totalChapters = 0,
    this.readChapters = 0,
    this.rating = 0.0,
    this.publishYear,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ─── Read Progress ────────────────────────────────────────────────────────────
  double get readProgress {
    if (totalChapters == 0) return 0;
    return (readChapters / totalChapters).clamp(0.0, 1.0);
  }

  bool get isCompleted => status == 'Hoàn thành';

  String get progressText =>
      totalChapters > 0 ? '$readChapters/$totalChapters chương' : '$readChapters chương';

  // ─── DB Serialization ─────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'author': author,
      'genre': genre,
      'status': status,
      'description': description,
      'cover_url': coverUrl,
      'total_chapters': totalChapters,
      'read_chapters': readChapters,
      'rating': rating,
      'publish_year': publishYear,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Manga.fromMap(Map<String, dynamic> map) {
    return Manga(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      genre: map['genre'] as String,
      status: map['status'] as String,
      description: map['description'] as String? ?? '',
      coverUrl: map['cover_url'] as String? ?? '',
      totalChapters: map['total_chapters'] as int? ?? 0,
      readChapters: map['read_chapters'] as int? ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      publishYear: map['publish_year'] as int?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Manga copyWith({
    int? id,
    String? title,
    String? author,
    String? genre,
    String? status,
    String? description,
    String? coverUrl,
    int? totalChapters,
    int? readChapters,
    double? rating,
    int? publishYear,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Manga(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      totalChapters: totalChapters ?? this.totalChapters,
      readChapters: readChapters ?? this.readChapters,
      rating: rating ?? this.rating,
      publishYear: publishYear ?? this.publishYear,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Manga(id: $id, title: $title, author: $author)';
  }
}
