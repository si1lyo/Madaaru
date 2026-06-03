import 'package:flutter/material.dart';

class PageE extends StatelessWidget {
  const PageE({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page E')),
      body: const Center(
        child: Text('ここは担当者Eのページ'),
      ),
    );
  }
}