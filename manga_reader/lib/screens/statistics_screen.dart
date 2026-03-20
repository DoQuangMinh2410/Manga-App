// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/manga_provider.dart';
import '../models/reading_history.dart';
import '../widgets/app_widgets.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MangaProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              title: Text('Thống kê'),
            ),
            if (provider.statsLoading)
              const SliverFillRemaining(
                child: AppLoadingIndicator(message: 'Đang tải thống kê...'),
              )
            else if (provider.stats == null)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  title: 'Chưa có dữ liệu',
                  subtitle: 'Thêm truyện để xem thống kê',
                  icon: Icons.bar_chart_rounded,
                ),
              )
            else
              SliverToBoxAdapter(
                child: _StatsContent(stats: provider.stats!),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }
}

class _StatsContent extends StatelessWidget {
  final MangaStats stats;
  const _StatsContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Summary Cards ────────────────────────────────────────────────────
          _buildSummaryCards(context),
          const SizedBox(height: 24),

          // ─ Status Pie Chart ─────────────────────────────────────────────────
          SectionHeader(title: 'Trạng thái đọc'),
          const SizedBox(height: 12),
          _buildStatusPieChart(context),
          const SizedBox(height: 24),

          // ─ Weekly Reading Bar Chart ──────────────────────────────────────────
          SectionHeader(title: 'Chương đọc trong 7 ngày'),
          const SizedBox(height: 12),
          _buildWeeklyBarChart(context),
          const SizedBox(height: 24),

          // ─ Genre Distribution ────────────────────────────────────────────────
          SectionHeader(title: 'Phân bố thể loại'),
          const SizedBox(height: 12),
          _buildGenreList(context),
        ],
      ),
    );
  }

  // ─── Summary Cards ───────────────────────────────────────────────────────────
  Widget _buildSummaryCards(BuildContext context) {
    final theme = Theme.of(context);
    final cards = [
      _SummaryCardData(
        icon: Icons.menu_book_rounded,
        label: 'Tổng truyện',
        value: '${stats.totalManga}',
        color: theme.colorScheme.primary,
      ),
      _SummaryCardData(
        icon: Icons.check_circle_rounded,
        label: 'Hoàn thành',
        value: '${stats.completedManga}',
        color: const Color(0xFF43C6AC),
      ),
      _SummaryCardData(
        icon: Icons.chrome_reader_mode_rounded,
        label: 'Tổng chương đọc',
        value: '${stats.totalChaptersRead}',
        color: theme.colorScheme.secondary,
      ),
      _SummaryCardData(
        icon: Icons.star_rounded,
        label: 'Đánh giá TB',
        value: stats.averageRating > 0
            ? stats.averageRating.toStringAsFixed(1)
            : 'N/A',
        color: Colors.amber,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _SummaryCard(data: cards[i]),
    );
  }

  // ─── Status Pie Chart ─────────────────────────────────────────────────────────
  Widget _buildStatusPieChart(BuildContext context) {
    final theme = Theme.of(context);
    if (stats.totalManga == 0) {
      return _emptyChart(context, 'Chưa có truyện');
    }

    const colors = [
      Color(0xFF6C63FF),
      Color(0xFF43C6AC),
      Color(0xFFFFB347),
      Color(0xFFFF6584),
    ];
    final labels = [
      'Đang đọc',
      'Hoàn thành',
      'Tạm dừng',
      'Bị hủy',
    ];
    final values = [
      stats.readingManga,
      stats.completedManga,
      stats.pausedManga,
      stats.cancelledManga,
    ];

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] > 0) {
        sections.add(PieChartSectionData(
          value: values[i].toDouble(),
          color: colors[i % colors.length],
          radius: 70,
          title: '${values[i]}',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          badgeWidget: null,
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < values.length; i++)
                if (values[i] > 0)
                  _LegendItem(
                    color: colors[i % colors.length],
                    label: labels[i],
                    value: values[i],
                  ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Weekly Bar Chart ─────────────────────────────────────────────────────────
  Widget _buildWeeklyBarChart(BuildContext context) {
    final theme = Theme.of(context);
    final weekly = stats.weeklyReading;

    if (weekly.isEmpty || weekly.every((d) => d.chaptersRead == 0)) {
      return _emptyChart(context, 'Chưa có lịch sử đọc tuần này');
    }

    final maxY =
        weekly.map((d) => d.chaptersRead.toDouble()).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY < 5 ? 5 : maxY + maxY * 0.2,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} chương',
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              getDrawingHorizontalLine: (v) => FlLine(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                  interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= weekly.length) {
                      return const SizedBox.shrink();
                    }
                    final day = weekly[index].date;
                    final label =
                        DateFormat('dd/MM').format(day);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < weekly.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: weekly[i].chaptersRead.toDouble(),
                      color: weekly[i].chaptersRead > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.2),
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      gradient: weekly[i].chaptersRead > 0
                          ? LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.6),
                                theme.colorScheme.primary,
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Genre Distribution List ──────────────────────────────────────────────────
  Widget _buildGenreList(BuildContext context) {
    final theme = Theme.of(context);
    if (stats.genreDistribution.isEmpty) {
      return _emptyChart(context, 'Chưa có dữ liệu thể loại');
    }

    final sorted = stats.genreDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    const genreColors = [
      Color(0xFF6C63FF),
      Color(0xFFFF6584),
      Color(0xFF43C6AC),
      Color(0xFFFFB347),
      Color(0xFF4ECDC4),
      Color(0xFFFF6B6B),
      Color(0xFF45B7D1),
      Color(0xFFA8E6CF),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sorted.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _GenreBarRow(
              genre: sorted[i].key,
              count: sorted[i].value,
              total: maxVal,
              color: genreColors[i % genreColors.length],
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyChart(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          msg,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.45),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────
class _SummaryCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: data.color,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  data.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                    fontSize: 11,
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
  }
}

// ─── Legend Item ──────────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ($value)',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

// ─── Genre Bar Row ────────────────────────────────────────────────────────────
class _GenreBarRow extends StatelessWidget {
  final String genre;
  final int count;
  final int total;
  final Color color;

  const _GenreBarRow({
    required this.genre,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            genre,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.12),
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
