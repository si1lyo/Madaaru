import 'package:flutter/material.dart';

class PageD extends StatelessWidget {
  const PageD({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page D')),
      body: const Center(
        child: Text('ここは担当者Dのページ'),
      ),
    );
  }
}