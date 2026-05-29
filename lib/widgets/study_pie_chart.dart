import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/study_data.dart';

class StudyPieChart extends StatelessWidget {
  final List<StudyData> data;

  const StudyPieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final totalHours  = data.fold(0.0, (sum, d) => sum + d.hours);
    final totalTarget = data.fold(0.0, (sum, d) => sum + d.targetHours);
    final achieved    = totalHours.clamp(0.0, totalTarget);
    final remaining   = (totalTarget - achieved).clamp(0.0, totalTarget);
    final percent     = (achieved / totalTarget * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '目標達成率',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '合計 ${totalHours.toStringAsFixed(1)}h / 目標 ${totalTarget.toStringAsFixed(1)}h',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 240,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sections: [
                      // 達成分
                      PieChartSectionData(
                        value: achieved,
                        title: '$percent%',
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        color: Colors.teal ,
                        radius: 100,
                      ),
                      // 未達成分
                      PieChartSectionData(
                        value: remaining,
                        title: remaining > 0
                            ? '残 ${remaining.toStringAsFixed(1)}h'
                            : '',
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        color: Colors.teal.withOpacity(0.4),
                        radius: 100,
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                  ),
                ),
              ),
              // 凡例
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legend(Colors.teal, '達成  ${achieved.toStringAsFixed(1)}h'),
                  const SizedBox(height: 8),
                  _legend(const Color(0xFFE0E0E0), '未達成  ${remaining.toStringAsFixed(1)}h'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}