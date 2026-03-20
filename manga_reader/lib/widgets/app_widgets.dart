// lib/widgets/app_widgets.dart
// Tập hợp các widget tái sử dụng

import 'package:flutter/material.dart';

// ─── Loading Indicator ────────────────────────────────────────────────────────
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  const AppLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State Widget ───────────────────────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.menu_book_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Confirmation Dialog ──────────────────────────────────────────────────────
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Xác nhận',
    this.cancelLabel = 'Hủy',
    this.confirmColor,
    this.icon,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy',
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmationDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dangerColor = confirmColor ?? theme.colorScheme.error;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: dangerColor, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: dangerColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

// ─── Star Rating Widget ───────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  final double maxRating;
  final int starCount;
  final double size;
  final Color? color;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 10.0,
    this.starCount = 5,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final starValue = rating / maxRating * starCount;
    final starColor = color ?? Colors.amber;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (i) {
        final fill = (starValue - i).clamp(0.0, 1.0);
        return Icon(
          fill >= 0.75
              ? Icons.star_rounded
              : fill >= 0.25
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: starColor,
          size: size,
        );
      }),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color _getColor() {
    switch (status) {
      case 'Hoàn thành':
        return const Color(0xFF43C6AC);
      case 'Đang tiến hành':
        return const Color(0xFF6C63FF);
      case 'Tạm dừng':
        return const Color(0xFFFFB347);
      case 'Bị hủy':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Cover Image Widget ───────────────────────────────────────────────────────
class MangaCoverImage extends StatelessWidget {
  final String coverUrl;
  final String title;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const MangaCoverImage({
    super.key,
    required this.coverUrl,
    required this.title,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  String _getInitials() {
    final words = title.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return title.isNotEmpty ? title[0].toUpperCase() : '?';
  }

  Color _getColor() {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6584),
      const Color(0xFF43C6AC),
      const Color(0xFFFFB347),
      const Color(0xFF4ECDC4),
      const Color(0xFFFF6B6B),
      const Color(0xFF45B7D1),
      const Color(0xFFA8E6CF),
    ];
    final index = title.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    if (coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          coverUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(radius),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildShimmer(radius);
          },
        ),
      );
    }

    return _buildPlaceholder(radius);
  }

  Widget _buildPlaceholder(BorderRadius radius) {
    final color = _getColor();
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
        ),
        child: Center(
          child: Text(
            _getInitials(),
            style: TextStyle(
              color: Colors.white,
              fontSize: (width * 0.35).clamp(14.0, 36.0),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }
}
