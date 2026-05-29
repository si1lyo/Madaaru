// study_bar_chart.dart（既存コードを data 対応に修正）
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/study_data.dart';

class StudyBarChart extends StatelessWidget {
  final List<StudyData> data;

  const StudyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxHours = data.map((d) => d.hours).reduce((a, b) => a > b ? a : b);
    final maxY = (maxHours / 2).ceil() * 2.0 + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '今週の勉強時間',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text('科目別（時間）', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${data[groupIndex].subject}\n${rod.toY.toStringAsFixed(1)}h',
                      const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          data[index].subject,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}h',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return _bar(entry.key, entry.value.hours, entry.value.color, maxY);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _bar(int x, double y, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.black.withOpacity(0.05),
          ),
        ),
      ],
    );
  }
}