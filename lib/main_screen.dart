import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'calender_page.dart';
import 'camera_page.dart';
import 'setting_page/setting_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // 最初はホームを表示
  final Color themeColor = const Color(0xFF0F624C);

  final List<Widget> _screens = [
    const CalendarPage(),
    const HomePage(),
    const SettingPage(),
  ];

  // --- 長押しで表示する「詳細登録」シート ---
  void _showAddProductSheet() {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    String selectedGenre = '食品';
    bool saveToGroup = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('詳細登録', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: '商品名', hintText: '例：明治おいしい牛乳')),
                  TextField(controller: typeController, decoration: const InputDecoration(labelText: '物', hintText: '例：牛乳')),
                  const SizedBox(height: 20),
                  const Text('ジャンル'),
                  DropdownButton<String>(
                    value: selectedGenre,
                    isExpanded: true,
                    items: ['食品', '日用品', 'その他'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) => setSheetState(() => selectedGenre = val!),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('グループに共有する'),
                    secondary: const Icon(Icons.groups),
                    value: saveToGroup,
                    onChanged: (val) => setSheetState(() => saveToGroup = val),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        // 名前チェック
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('商品名を入力してください')));
                          return;
                        }

                        // グループ所属チェック
                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                        final String? groupId = userDoc.data()?['groupId'];

                        if (saveToGroup && (groupId == null || groupId.isEmpty)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('グループに所属していません。設定からグループを作成・参加してください。'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        // 保存処理
                        CollectionReference targetCollection;
                        if (saveToGroup && groupId != null) {
                          targetCollection = FirebaseFirestore.instance.collection('groups').doc(groupId).collection('group_products');
                        } else {
                          targetCollection = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('my_products');
                        }

                        await targetCollection.add({
                          'name': nameController.text.trim(),
                          'type': typeController.text.trim(),
                          'genre': selectedGenre,
                          'purchaseDate': Timestamp.now(),
                          'registeredBy': user.displayName ?? user.email,
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameController.text} を追加しました')));
                        }
                      },
                      child: const Text('リストに追加'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: GestureDetector(
        onLongPress: _showAddProductSheet, // 長押しで手入力
        child: FloatingActionButton(
          onPressed: () {
            // タップでカメラ
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraPage()));
          },
          backgroundColor: themeColor,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        padding: EdgeInsets.zero,
        height: 75,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.calendar_month_outlined, color: _currentIndex == 0 ? themeColor : Colors.grey),
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: _currentIndex == 1 ? themeColor : Colors.grey),
              onPressed: () => setState(() => _currentIndex = 1),
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: _currentIndex == 2 ? themeColor : Colors.grey),
              onPressed: () => setState(() => _currentIndex = 2),
            ),
          ],
        ),
      ),
    );
  }
}