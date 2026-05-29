// study_data.dart
import 'package:flutter/material.dart';

class StudyData {
  final String subject;
  final double hours;
  final double targetHours;
  final Color color;

  const StudyData({
    required this.subject,
    required this.hours,
    required this.targetHours,
    required this.color,
  });
}

// 共通データ定義
const List<StudyData> studyDataList = [
  StudyData(subject: '数学', hours: 8.5, targetHours: 10.0, color: Colors.teal),
  StudyData(subject: '英語', hours: 6.0, targetHours: 8.0,  color: Colors.teal),
  StudyData(subject: '理科', hours: 4.5, targetHours: 6.0,  color: Colors.teal),
  StudyData(subject: '国語', hours: 3.0, targetHours: 5.0,  color: Colors.teal),
  StudyData(subject: '社会', hours: 5.5, targetHours: 6.0,  color: Colors.teal),
];

const int time = 0;