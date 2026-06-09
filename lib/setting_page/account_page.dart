import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ログイン情報を扱うために必要

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 現在ログインしているユーザーの情報を取得
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント・データ管理'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'ログイン情報',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('メールアドレス'),
            // ログインしていればアドレスを表示、していなければ「未ログイン」
            subtitle: Text(user?.email ?? 'ログインしていません'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'アカウント操作',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // ログアウト処理を実行
              await FirebaseAuth.instance.signOut();
              // ログアウトすると main.dart の StreamBuilder が検知して
              // 自動的にログイン画面に戻るので、この画面を閉じるだけでOK
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('退会（アカウント削除）', style: TextStyle(color: Colors.red)),
            onTap: () {
              // ここに退会処理（確認ダイアログなど）を将来的に書く
            },
          ),
        ],
      ),
    );
  }
}