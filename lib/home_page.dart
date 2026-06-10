import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // 1. メインのスワイプ（マイリスト vs グループ）用
  late TabController _mainTabController;
  // 2. カテゴリ選択（すべて、食品など）用
  int _selectedCategoryIndex = 0;
  
  final Color personalColor = const Color(0xFF0F624C);
  final Color groupColor = Colors.orange;
  String? _groupName;

  // 現在のメイン画面（0:マイ、1:グループ）に応じた色を返す
  Color get activeColor => _mainTabController.index == 1 ? groupColor : personalColor;

  @override
  void initState() {
    super.initState();
    // 初期状態は2タブ（マイリスト、グループ）。スワイプを検知するためにListenerを追加
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (!_mainTabController.indexIsChanging) {
        setState(() {}); // スワイプが終わったら色を更新
      }
    });
    _fetchGroupInfo();
  }

  Future<void> _fetchGroupInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final gid = userDoc.data()?['groupId'];
      if (gid != null) {
        final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(gid).get();
        if (mounted) {
          setState(() {
            _groupName = groupDoc.data()?['groupName'];
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // 上部のトグルもスワイプと連動
        title: _buildTitleToggle(),
        centerTitle: true,
        // カテゴリタブはタップ専用として実装
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildCategoryBar(),
        ),
      ),
      // TabBarViewによって、左右のスワイプで画面が切り替わる
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildProductList(isGroup: false), // マイリスト画面
          _groupName != null 
            ? _buildProductList(isGroup: true) // グループ画面
            : const Center(child: Text('グループに所属していません')),
        ],
      ),
    );
  }

  // --- 画面上部の「マイリスト | グループ」切り替え（タップでもスワイプでも動く） ---
  Widget _buildTitleToggle() {
    bool isGroup = _mainTabController.index == 1;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem('マイリスト', !isGroup, () => _mainTabController.animateTo(0)),
          if (_groupName != null)
            _toggleItem(_groupName!, isGroup, () => _mainTabController.animateTo(1)),
        ],
      ),
    );
  }

  Widget _toggleItem(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  // --- カテゴリ選択バー（タップで状態を変更） ---
  Widget _buildCategoryBar() {
    final categories = ['すべて', '食品', '日用品', 'その他'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(categories.length, (index) {
          bool isSelected = _selectedCategoryIndex == index;
          return InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? activeColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- リスト表示 ---
  Widget _buildProductList({required bool isGroup}) {
    // カテゴリに応じたフィルタリングのデモ用データ
    final List<Map<String, dynamic>> products = isGroup 
      ? [{'name': '【共有】トイレットペーパー', 'days': '残り約5日', 'percent': 0.3}]
      : [{'name': '牛乳', 'days': '残り約2日', 'percent': 0.2}];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(product['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(product['days'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: product['percent'],
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                  minHeight: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}