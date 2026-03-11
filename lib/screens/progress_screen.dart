import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/workout_service.dart';
import '../widgets/share_cards.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _rangeIndex = 0;
  WorkoutService get _ws => WorkoutService.instance;

  static const _rangeLabels = ['Ten tydzień', 'Ten miesiąc', 'Ostatnie 3 miesiące', 'Ten rok'];
  static const _rangeSubs = [
    'treningi tego tygodnia',
    'treningi tego miesiąca',
    'treningi z ostatnich 3 miesięcy',
    'treningi tego roku',
  ];

  @override
  Widget build(BuildContext context) {
    final records = _ws.personalRecords;
    final muscleStats = _ws.muscleGroupStatsInRange(_rangeIndex);
    final chartData = _ws.activityData(_rangeIndex);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Postępy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Zakres ──────────────────────────────────
          _TimeRangePicker(
            selected: _rangeIndex,
            onChanged: (i) => setState(() => _rangeIndex = i),
          ),
          const SizedBox(height: 24),

          // ── Wykres aktywności ────────────────────────
          Text('Aktywność', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          _ActivityChart(data: chartData, rangeIndex: _rangeIndex),
          const SizedBox(height: 28),

          // ── Podsumowanie zakresu ─────────────────────
          Text(_rangeLabels[_rangeIndex], style: textTheme.titleLarge),
          const SizedBox(height: 12),
          _MonthSummary(
            count: _ws.countInRange(_rangeIndex),
            duration: _ws.durationInRange(_rangeIndex),
            volume: _ws.volumeInRange(_rangeIndex),
          ),
          const SizedBox(height: 28),

          // ── Rozkład partii ciała ─────────────────────
          Text('Rozkład partii ciała', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Liczba serii per partia ciała (${_rangeSubs[_rangeIndex]})',
              style: textTheme.bodySmall?.copyWith(color: AppTheme.textSec(context))),
          const SizedBox(height: 16),
          _MuscleGroupChart(stats: muscleStats),
          const SizedBox(height: 28),

          // ── Rekordy osobiste ─────────────────────────
          Text('Rekordy osobiste', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(children: [
                Icon(Icons.emoji_events_outlined,
                    color: AppTheme.textSec(context), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Brak rekordów', style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text('Ukończ trening i dodaj obciążenie, żeby zobaczyć tutaj swoje najlepsze wyniki!',
                          style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ]),
            )
          else
            ...records.entries
                .toList()
                .sorted()
                .take(10)
                .map((e) => _RecordTile(name: e.key, weight: e.value)),
        ]),
      ),
    );
  }
}

extension _SortedExt on List<MapEntry<String, double>> {
  List<MapEntry<String, double>> sorted() {
    final copy = List<MapEntry<String, double>>.from(this);
    copy.sort((a, b) => b.value.compareTo(a.value));
    return copy;
  }
}

// ── Time range picker ────────────────────────────────────

class _TimeRangePicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _TimeRangePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Tydzień', 'Miesiąc', '3 mies.', 'Rok'];
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: List.generate(labels.length, (i) => Expanded(
        child: GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected == i ? accent : AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected == i ? accent : AppTheme.border(context)),
            ),
            alignment: Alignment.center,
            child: Text(labels[i], style: TextStyle(
              color: selected == i ? Colors.white : AppTheme.textSec(context),
              fontWeight: selected == i ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
          ),
        ),
      )),
    );
  }
}

// ── Wykres słupkowy aktywności ───────────────────────────

class _ActivityChart extends StatelessWidget {
  final List<int> data;
  final int rangeIndex;
  const _ActivityChart({required this.data, required this.rangeIndex});

  String _bottomLabel(int rangeIndex, int i) {
    const dayLabels = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
    const monthLabels = ['Sty', 'Lut', 'Mar', 'Kwi', 'Maj', 'Cze', 'Lip', 'Sie', 'Wrz', 'Paź', 'Lis', 'Gru'];
    switch (rangeIndex) {
      case 0: return dayLabels[i];
      case 1: return '${i + 1}';
      case 2: return 'T${i + 1}';
      case 3: return monthLabels[i];
      default: return '${i + 1}';
    }
  }

  bool _showLabel(int rangeIndex, int i) {
    switch (rangeIndex) {
      case 0: return true;
      case 1: return i % 5 == 0;
      case 2: return i % 2 == 0;
      case 3: return true;
      default: return true;
    }
  }

  double _barWidth(int rangeIndex) {
    switch (rangeIndex) {
      case 0: return 24;
      case 1: return 8;
      case 2: return 14;
      case 3: return 16;
      default: return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxY = (data.fold(0, (a, b) => a > b ? a : b) + 1.0).clamp(2.0, 999.0);
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridLineColor = isDark ? Colors.white10 : Colors.black12;
    final emptyBarColor = isDark ? Colors.white12 : Colors.black12;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.transparent,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridLineColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                if (!_showLabel(rangeIndex, i)) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(_bottomLabel(rangeIndex, i), style: TextStyle(
                    color: AppTheme.textSec(context), fontSize: 11)));
              },
            )),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(data.length, (i) => BarChartGroupData(
            x: i,
            barRods: [BarChartRodData(
              toY: data[i].toDouble(),
              color: data[i] > 0 ? accent : emptyBarColor,
              width: _barWidth(rangeIndex),
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true, toY: maxY,
                color: accent.withValues(alpha: 0.05),
              ),
            )],
          )),
        ),
      ),
    );
  }
}

// ── Wykres rozkładu partii ciała ─────────────────────────

class _MuscleGroupChart extends StatelessWidget {
  final Map<String, Map<String, int>> stats;
  const _MuscleGroupChart({required this.stats});

  static const _colors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF45B7D1),
    Color(0xFFF7DC6F), Color(0xFFBB8FCE), Color(0xFF82E0AA),
    Color(0xFFF0B27A), Color(0xFF85C1E9), Color(0xFFABEBC6),
    Color(0xFFD2B4DE),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(children: [
          Icon(Icons.bar_chart, color: AppTheme.textSec(context), size: 40),
          const SizedBox(height: 12),
          Tooltip(
            message: 'Rozkład uzupełni się po zakończeniu treningu z ćwiczeniami z bazy',
            child: Text(
              'Brak danych w tym zakresie czasu.\nUkończ treningi z przypisanymi ćwiczeniami,\naby zobaczyć rozkład partii ciała.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSec(context), fontSize: 13),
            ),
          ),
        ]),
      );
    }

    final entries = stats.entries.toList()
      ..sort((a, b) => (b.value['sets'] ?? 0).compareTo(a.value['sets'] ?? 0));
    final maxSets = entries.first.value['sets'] ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _LegendDot(color: accent),
          const SizedBox(width: 6),
          Text('Serie', style: TextStyle(color: AppTheme.textSec(context), fontSize: 12)),
          const SizedBox(width: 16),
          const _LegendDot(color: Color(0xFF42A5F5)),
          const SizedBox(width: 6),
          Text('Ćwiczenia', style: TextStyle(color: AppTheme.textSec(context), fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        ...entries.asMap().entries.map((mapEntry) {
          final idx = mapEntry.key;
          final name = mapEntry.value.key;
          final sets = mapEntry.value.value['sets'] ?? 0;
          final exCount = mapEntry.value.value['exercises'] ?? 0;
          final color = _colors[idx % _colors.length];
          final fraction = sets / maxSets;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                  child: Text(name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text('$sets serii  |  $exCount ćw.',
                    style: TextStyle(color: AppTheme.textSec(context), fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              Stack(children: [
                Container(
                  height: 12, width: double.infinity,
                  decoration: BoxDecoration(
                    color: barBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ]),
            ]),
          );
        }),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ── Podsumowanie miesiąca ────────────────────────────────

class _MonthSummary extends StatelessWidget {
  final int count, duration;
  final double volume;
  const _MonthSummary({required this.count, required this.duration, required this.volume});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final items = [
      ('Treningi', '$count', Icons.fitness_center, accent),
      ('Łączny czas', '$duration min', Icons.timer, const Color(0xFF42A5F5)),
      ('Objętość', '${volume.toStringAsFixed(0)} kg', Icons.bar_chart, AppTheme.success),
    ];
    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Expanded(child: Container(
          margin: EdgeInsets.only(right: i < items.length - 1 ? 12 : 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(children: [
            Icon(item.$3, color: item.$4, size: 22),
            const SizedBox(height: 8),
            Text(item.$2, style: TextStyle(
              color: item.$4, fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(item.$1, style: TextStyle(
              color: AppTheme.textSec(context), fontSize: 11)),
          ]),
        ));
      }).toList(),
    );
  }
}

// ── Rekord osobisty ──────────────────────────────────────

class _RecordTile extends StatelessWidget {
  final String name;
  final double weight;
  const _RecordTile({required this.name, required this.weight});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(children: [
        const Icon(Icons.emoji_events, color: AppTheme.warning, size: 24),
        const SizedBox(width: 14),
        Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
        Text('${weight == weight.roundToDouble() ? weight.toInt() : weight} kg',
            style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Udostępnij rekord',
          child: IconButton(
            icon: const Icon(Icons.ios_share, color: AppTheme.textSecond, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => SharePreviewDialog(
                  cardWidget: RecordShareCard(
                    exerciseName: name,
                    weight: weight,
                    date: DateTime.now(), // Fallback na dzisiejszą datę
                  ),
                  shareFileName: 'rekord_${name.replaceAll(' ', '_')}',
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
