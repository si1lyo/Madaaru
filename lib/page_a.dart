import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/study_bar_chart.dart';
import './widgets/study_pie_chart.dart';
import './widgets/study_bar_chart.dart';
import './data/study_data.dart';

class PageA extends StatelessWidget {
  const PageA({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('勉強アプリ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildTodayCard()],
        ),
      ),
    );
  }

  Widget _buildTodayCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        StudyPieChart(data: studyDataList),
        SizedBox(height: 20),
        StudyBarChart(data: studyDataList),
      ],
    );
  }
}
