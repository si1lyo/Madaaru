import 'package:flutter/material.dart';
import 'main_screen.dart'; // 1. さっき作った main_screen.dart を読み込む

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'まだある？',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}