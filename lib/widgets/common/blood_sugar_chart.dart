import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/blood_sugar_record.dart';
import '../../themes/app_theme.dart';

class BloodSugarChart extends StatefulWidget {
  final List<BloodSugarRecord> records;
  final BloodSugarType? filterType;
  final ChartPeriod period;

  const BloodSugarChart({
    super.key,
    required this.records,
    this.filterType,
    this.period = ChartPeriod.weekly,
  });

  @override
  State<BloodSugarChart> createState() => _BloodSugarChartState();
}

enum ChartPeriod { daily, weekly, monthly }

class _BloodSugarChartState extends State<BloodSugarChart> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: _buildChart(),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ChartPeriod.values.map((period) {
        final isSelected = widget.period == period;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(
              period.name[0].toUpperCase() + period.name.substring(1),
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppTheme.primaryColor,
            backgroundColor: AppTheme.backgroundColor,
            onSelected: (_) {},
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart() {
    final filtered = widget.filterType != null
        ? widget.records
            .where((r) => r.type == widget.filterType)
            .toList()
        : widget.records;

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No data to display',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final now = DateTime.now();
    late List<BloodSugarRecord> periodRecords;
    late List<String> labels;

    switch (widget.period) {
      case ChartPeriod.daily:
        periodRecords = filtered
            .where((r) =>
                r.dateTime.day == now.day &&
                r.dateTime.month == now.month &&
                r.dateTime.year == now.year)
            .toList();
        labels = List.generate(
            24, (i) => '${i.toString().padLeft(2, '0')}:00');
      case ChartPeriod.weekly:
        periodRecords = filtered
            .where((r) =>
                r.dateTime.isAfter(now.subtract(const Duration(days: 7))))
            .toList();
        labels = List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          return DateFormat('E').format(d);
        });
      case ChartPeriod.monthly:
        periodRecords = filtered
            .where((r) =>
                r.dateTime.month == now.month &&
                r.dateTime.year == now.year)
            .toList();
        labels = List.generate(
            DateTime(now.year, now.month + 1, 0).day, (i) => '${i + 1}');
    }

    if (periodRecords.isEmpty) {
      return const Center(
        child: Text(
          'No data for this period',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < periodRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), periodRecords[i].value));
    }

    final maxY = periodRecords
            .fold<double>(0, (max, r) => r.value > max ? r.value : max) *
        1.2;
    final minY = periodRecords
            .fold<double>(double.infinity,
                (min, r) => r.value < min ? r.value : min) *
        0.8;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 100 ? 50 : 2,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < labels.length && idx % 2 == 0) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      labels[idx],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (periodRecords.length - 1).toDouble().clamp(1, double.infinity),
        minY: minY > 0 ? 0 : minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
