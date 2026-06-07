import 'package:flutter/material.dart';

// 1. クラスの定義
class RegisteredProductsPage extends StatefulWidget {
  const RegisteredProductsPage({super.key});

  @override
  State<RegisteredProductsPage> createState() => _RegisteredProductsPageState();
}

// 2. 画面の状態（見た目）を管理する部分
class _RegisteredProductsPageState extends State<RegisteredProductsPage> {
  // テスト用のダミーデータ（あとでFirebaseから読み込むようにします）
  final List<String> products = ['牛乳', 'シャンプー', '歯ブラシ','洗剤'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登録商品一覧'),
      ),
      // 3. リストを表示する
      body: ListView.builder(
        itemCount: products.length, // リストの数
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.inventory_2),
            title: Text(products[index]), // 商品名を表示
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // ここに商品詳細への遷移などを書く
            },
          );
        },
      ),
    );
  }
}