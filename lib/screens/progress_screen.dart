import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Postępy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Zakresy czasu ─────────────────────────────
            _TimeRangePicker(),
            const SizedBox(height: 24),

            // ── Wykres treningów w tygodniu ───────────────
            Text('Treningi w tygodniu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _WeeklyChart(),
            const SizedBox(height: 28),

            // ── Rekordy ───────────────────────────────────
            Text('Rekordy osobiste', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _PersonalRecords(),
            const SizedBox(height: 28),

            // ── Podsumowanie miesiąca ─────────────────────
            Text('Ten miesiąc', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _MonthSummary(),
          ],
        ),
      ),
    );
  }
}

class _TimeRangePicker extends StatefulWidget {
  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  int _selected = 0;
  final List<String> _ranges = ['Tydzień', 'Miesiąc', '3 mies.', 'Rok'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_ranges.length, (i) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selected = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: i < _ranges.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _selected == i ? AppTheme.accent : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              _ranges[i],
              style: TextStyle(
                color: _selected == i ? Colors.white : AppTheme.textSecond,
                fontWeight: _selected == i ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  const days = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
                  return Text(days[v.toInt()],
                      style: const TextStyle(color: AppTheme.textSecond, fontSize: 12));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(7, (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: [0, 0, 0, 0, 0, 0, 0][i].toDouble(),
                color: AppTheme.accent,
                width: 18,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 2,
                  color: AppTheme.accent.withValues(alpha: 0.08),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _PersonalRecords extends StatelessWidget {
  final _records = const [
    ('Wyciskanie sztangi', '– kg', Icons.emoji_events),
    ('Martwy ciąg', '– kg', Icons.emoji_events),
    ('Przysiady', '– kg', Icons.emoji_events),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _records.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(r.$3, color: AppTheme.warning, size: 24),
            const SizedBox(width: 14),
            Expanded(child: Text(r.$1, style: Theme.of(context).textTheme.titleMedium)),
            Text(r.$2, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      )).toList(),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Treningi', '0', Icons.fitness_center, AppTheme.accent),
      ('Łączny czas', '0 min', Icons.timer, const Color(0xFF42A5F5)),
      ('Objętość', '0 kg', Icons.bar_chart, AppTheme.success),
    ];
    return Row(
      children: items.map((item) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: item == items.last ? 0 : 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(item.$3, color: item.$4, size: 22),
              const SizedBox(height: 8),
              Text(item.$2, style: TextStyle(
                color: item.$4, fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 4),
              Text(item.$1, style: const TextStyle(
                color: AppTheme.textSecond, fontSize: 11)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
