import 'package:flutter/material.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  final Color themeColor = const Color(0xFF0F624C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F624C),
      appBar: AppBar(backgroundColor: Colors.white,
      elevation: 0,
      leading: const Icon(Icons.arrow_back, color: Colors.black,)),

      body: const Center(
        child: Text('ここは担当者Cのページ'),
      ),
    );
  }
}