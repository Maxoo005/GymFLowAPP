import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/workout_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _rangeIndex = 0; // 0=tydzień,1=miesiąc,2=3mies,3=rok
  WorkoutService get _ws => WorkoutService.instance;

  List<int> get _chartData {
    switch (_rangeIndex) {
      case 0: return _ws.weeklyActivity;
      case 1: return _monthData();
      default: return _ws.weeklyActivity;
    }
  }

  List<int> _monthData() {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final counts = List<int>.filled(daysInMonth, 0);
    for (final w in _ws.workouts) {
      if (w.date.year == now.year && w.date.month == now.month) {
        counts[w.date.day - 1]++;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final records = _ws.personalRecords;
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

          // ── Wykres ──────────────────────────────────
          Text('Aktywność', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          _ActivityChart(data: _chartData, rangeIndex: _rangeIndex),
          const SizedBox(height: 28),

          // ── Podsumowanie miesiąca ────────────────────
          Text('Ten miesiąc', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          _MonthSummary(
            count: _ws.monthlyCount,
            duration: _ws.monthlyDuration,
            volume: _ws.monthlyVolume,
          ),
          const SizedBox(height: 28),

          // ── Rekordy osobiste ─────────────────────────
          Text('Rekordy osobiste', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.emoji_events_outlined, color: AppTheme.textSecond, size: 28),
                const SizedBox(width: 12),
                Text('Ukończ trening, żeby zobaczyć rekordy!',
                    style: textTheme.bodyMedium),
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
    return Row(
      children: List.generate(labels.length, (i) => Expanded(
        child: GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected == i ? AppTheme.accent : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(labels[i], style: TextStyle(
              color: selected == i ? Colors.white : AppTheme.textSecond,
              fontWeight: selected == i ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
          ),
        ),
      )),
    );
  }
}

// ── Wykres słupkowy ──────────────────────────────────────

class _ActivityChart extends StatelessWidget {
  final List<int> data;
  final int rangeIndex;
  const _ActivityChart({required this.data, required this.rangeIndex});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
    final maxY = (data.fold(0, (a, b) => a > b ? a : b) + 1.0).clamp(2.0, 999.0);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.transparent,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final label = rangeIndex == 0 ? dayLabels[i] : '${i + 1}';
                if (rangeIndex == 1 && i % 5 != 0) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: const TextStyle(
                    color: AppTheme.textSecond, fontSize: 11)));
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
              color: data[i] > 0 ? AppTheme.accent : Colors.white12,
              width: rangeIndex == 0 ? 24 : 8,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true, toY: maxY,
                color: AppTheme.accent.withValues(alpha: 0.05),
              ),
            )],
          )),
        ),
      ),
    );
  }
}

// ── Podsumowanie miesiąca ────────────────────────────────

class _MonthSummary extends StatelessWidget {
  final int count, duration;
  final double volume;
  const _MonthSummary({required this.count, required this.duration, required this.volume});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Treningi', '$count', Icons.fitness_center, AppTheme.accent),
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
            color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(item.$3, color: item.$4, size: 22),
            const SizedBox(height: 8),
            Text(item.$2, style: TextStyle(
              color: item.$4, fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(item.$1, style: const TextStyle(
              color: AppTheme.textSecond, fontSize: 11)),
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      const Icon(Icons.emoji_events, color: AppTheme.warning, size: 24),
      const SizedBox(width: 14),
      Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
      Text('${weight == weight.roundToDouble() ? weight.toInt() : weight} kg',
          style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 16)),
    ]),
  );
}
