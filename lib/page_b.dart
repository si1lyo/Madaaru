import 'package:flutter/material.dart';

class PageB extends StatelessWidget {
  const PageB({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page B')),
      body: const Center(
        child: Text('ここは担当者Bのページ'),
      ),
    );
  }
}