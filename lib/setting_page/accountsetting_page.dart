import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  String _generateGroupId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(5, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  void _createGroup() {
    final nameController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを新規作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "グループ名（例：田中家）")),
            TextField(controller: passController, decoration: const InputDecoration(labelText: "参加用パスワード")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              final newId = _generateGroupId();
              await _db.collection('groups').doc(newId).set({
                'groupName': nameController.text,
                'password': passController.text,
                'ownerId': user?.uid,
                'members': [user?.uid],
              });
              await _db.collection('users').doc(user?.uid).set({'groupId': newId}, SetOptions(merge: true));
              if (mounted) Navigator.pop(context);
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  void _joinGroup() {
    final idController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループに参加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idController, decoration: const InputDecoration(labelText: "グループIDを入力")),
            TextField(controller: passController, decoration: const InputDecoration(labelText: "パスワードを入力")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              final inputId = idController.text.toUpperCase();
              final doc = await _db.collection('groups').doc(inputId).get();
              if (doc.exists && doc.data()?['password'] == passController.text) {
                await _db.collection('groups').doc(inputId).update({
                  'members': FieldValue.arrayUnion([user?.uid])
                });
                await _db.collection('users').doc(user?.uid).set({'groupId': inputId}, SetOptions(merge: true));
                if (mounted) Navigator.pop(context);
              } else {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IDまたはパスワードが違います')));
              }
            },
            child: const Text('参加'),
          ),
        ],
      ),
    );
  }

  // --- 【修正・追加】グループ脱退・削除の統合処理 ---
  Future<void> _handleExitOrDeleteGroup(String groupId) async {
    if (user == null) return;

    // 1. 現在のグループ情報を取得
    final groupDoc = await _db.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) return;

    final List<dynamic> members = groupDoc.data()?['members'] ?? [];

    if (members.length > 1) {
      // 【ケース1】他にメンバーがいる場合 → 自分のUIDを抜くだけ
      await _db.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([user!.uid])
      });
      // 自分のユーザー情報のgroupIdも消す
      await _db.collection('users').doc(user!.uid).update({'groupId': FieldValue.delete()});
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('グループを脱退しました')));
    } else {
      // 【ケース2】自分が最後の1人の場合 → 確認ダイアログを出して完全削除
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('グループの削除'),
          content: const Text('あなたが最後のメンバーです。グループを削除すると、登録された商品データもすべて消去されます。よろしいですか？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除する', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmDelete == true) {
        // --- データの全削除（一括処理） ---
        WriteBatch batch = _db.batch();
        
        // ① group_products コレクションの中身をすべて取得してバッチに追加
        final productsRef = _db.collection('groups').doc(groupId).collection('group_products');
        final productsSnapshot = await productsRef.get();
        for (var product in productsSnapshot.docs) {
          batch.delete(product.reference);
        }
        
        // ② グループ本体を削除
        batch.delete(_db.collection('groups').doc(groupId));
        
        // ③ 自分のユーザー情報のgroupIdを削除
        batch.update(_db.collection('users').doc(user!.uid), {'groupId': FieldValue.delete()});

        // 実行
        await batch.commit();

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('グループとすべてのデータを削除しました')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント・グループ管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final String? groupId = userData?['groupId'];

          return ListView(
            children: [
              const _SectionHeader(title: 'ユーザー情報'),
              ListTile(leading: const Icon(Icons.person), title: Text(user?.displayName ?? '未設定')),
              
              const Divider(),
              const _SectionHeader(title: 'グループ設定'),
              if (groupId == null) ...[
                ListTile(leading: const Icon(Icons.group_add), title: const Text('グループを作成する'), onTap: _createGroup),
                ListTile(leading: const Icon(Icons.login), title: const Text('グループに参加する'), onTap: _joinGroup),
              ] else ...[
                FutureBuilder<DocumentSnapshot>(
                  future: _db.collection('groups').doc(groupId).get(),
                  builder: (context, gSnap) {
                    final gData = gSnap.data?.data() as Map<String, dynamic>?;
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.verified_user),
                          title: Text('所属：${gData?['groupName'] ?? "読込中..."}'),
                          subtitle: Text('グループID: $groupId (招待時に共有)'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.exit_to_app, color: Colors.red),
                          title: const Text('グループを脱退/削除'),
                          onTap: () => _handleExitOrDeleteGroup(groupId),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('ログアウト'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)));
  }
}