import 'package:flutter/material.dart';
import 'notification_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ホーム'),
      actions: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
               Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    
      ),
      body: const Center(
        child: Text('ここは担当者Aのページ'),
      ),
    );
  }
}