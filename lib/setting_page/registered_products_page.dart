import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 日付を綺麗に表示するための部品

class RegisteredProductsPage extends StatelessWidget {
  const RegisteredProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('登録商品一覧'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // StreamBuilderを使うと、Firestoreのデータが変わった瞬間に自動でリストが更新されます
      body: StreamBuilder<QuerySnapshot>(
        // 住所：usersフォルダ ＞ 自分のID ＞ my_productsフォルダ を見張る
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('my_products')
            .orderBy('purchaseDate', descending: true) // 買った日が新しい順に並べる
            .snapshots(),
        builder: (context, snapshot) {
          // 読み込み中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // データが空の場合
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('登録された商品はまだありません'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // 1つ分のデータを取得
              final data = docs[index].data() as Map<String, dynamic>;
              
              // Firestoreの「Timestamp」形式を「文字列」に変換
              final Timestamp? timestamp = data['purchaseDate'];
              final String dateStr = timestamp != null 
                  ? DateFormat('yyyy/MM/dd').format(timestamp.toDate())
                  : '日付不明';

              return ListTile(
                leading: const Icon(Icons.inventory_2, color: Color(0xFF0F624C)),
                title: Text(data['name'] ?? '商品名なし'),
                subtitle: Text('購入日: $dateStr'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          );
        },
      ),
    );
  }
}