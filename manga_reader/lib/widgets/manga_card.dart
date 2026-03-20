// lib/widgets/manga_card.dart
import 'package:flutter/material.dart';
import '../models/manga.dart';
import 'app_widgets.dart';

// ─── Grid Card ────────────────────────────────────────────────────────────────
class MangaGridCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;

  const MangaGridCard({
    super.key,
    required this.manga,
    required this.onTap,
    this.onFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Cover Image với Hero Animation ────────────────────────────────
            Stack(
              children: [
                Hero(
                  tag: 'manga_cover_${manga.id}',
                  child: MangaCoverImage(
                    coverUrl: manga.coverUrl,
                    title: manga.title,
                    width: double.infinity,
                    height: 150,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        manga.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: manga.isFavorite
                            ? const Color(0xFFFF6584)
                            : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: StatusBadge(status: manga.status),
                ),
              ],
            ),

            // ─ Info ──────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      manga.author,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Rating + Genre
                    Row(
                      children: [
                        if (manga.rating > 0) ...[
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            manga.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            manga.genre,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    if (manga.totalChapters > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: manga.readProgress,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.12),
                          color: theme.colorScheme.primary,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        manga.progressText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List Card ────────────────────────────────────────────────────────────────
class MangaListCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;

  const MangaListCard({
    super.key,
    required this.manga,
    required this.onTap,
    this.onFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('manga_${manga.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        if (onDelete != null) {
          onDelete!();
        }
        return false; // Xử lý xóa thông qua callback
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Cover với Hero Animation
              Hero(
                tag: 'manga_cover_${manga.id}',
                child: MangaCoverImage(
                  coverUrl: manga.coverUrl,
                  title: manga.title,
                  width: 70,
                  height: 95,
                  borderRadius: BorderRadius.circular(10),
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
                            manga.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onFavorite,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              manga.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: manga.isFavorite
                                  ? const Color(0xFFFF6584)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.3),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      manga.author,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(status: manga.status),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            manga.genre,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (manga.totalChapters > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: manga.readProgress,
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.12),
                                color: theme.colorScheme.primary,
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            manga.progressText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (manga.rating > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StarRating(rating: manga.rating, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            manga.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
