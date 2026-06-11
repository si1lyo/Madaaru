import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // 1. 左右スワイプ（マイリスト vs グループ）用
  late TabController _mainTabController;
  
  // 2. カテゴリ選択（すべて、食品など）用
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['すべて', '食品', '日用品', 'その他'];

  final Color personalColor = const Color(0xFF0F624C);
  final Color groupColor = Colors.orange;
  
  String? _groupName;
  String? _groupId;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // lengthを2にして、左右スワイプで「個人」と「グループ」を行き来させる
    _mainTabController = TabController(length: 2, vsync: this);
    
    // スワイプ中に色が滑らかに変わるようにリスナーを設定
    _mainTabController.addListener(() {
      setState(() {}); 
    });

    _fetchGroupInfo();
  }

  Future<void> _fetchGroupInfo() async {
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final gid = userDoc.data()?['groupId'];
      if (gid != null) {
        final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(gid).get();
        if (mounted) {
          setState(() {
            _groupId = gid;
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

  // 現在のタブ位置に応じて色を計算（スワイプ中も考慮）
  Color get activeColor => _mainTabController.index == 1 ? groupColor : personalColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _buildTitleToggle(), // 上部のスイッチ（タップでanimateToを呼ぶ）
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildCategoryBar(), // カテゴリバー（タップで絞り込み）
        ),
      ),
      // ★ ここが左右スワイプの本体です
      body: TabBarView(
        controller: _mainTabController,
        physics: const BouncingScrollPhysics(), // スワイプ感を良くする設定
        children: [
          _buildFirestoreList(isGroup: false), // 左：マイリスト
          _groupId != null 
            ? _buildFirestoreList(isGroup: true) // 右：グループ
            : const Center(child: Text('グループに所属していません')),
        ],
      ),
    );
  }

  // --- 画面上部のトグル（タップするとスワイプと同じ動きをする） ---
  Widget _buildTitleToggle() {
    bool isGroup = _mainTabController.index == 1;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
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
        child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  // --- カテゴリ選択バー（タップで表示を切り替えるフィルター） ---
  Widget _buildCategoryBar() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_categories.length, (index) {
          bool isSelected = _selectedCategoryIndex == index;
          return InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = index), // ここでカテゴリを変更
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: isSelected ? activeColor : Colors.transparent, 
                  width: 3
                )),
              ),
              child: Text(
                _categories[index], 
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                )
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Firestoreからデータを取得してカテゴリ別に表示 ---
  Widget _buildFirestoreList({required bool isGroup}) {
    if (user == null) return const Center(child: Text('ログインしてください'));

    Query query;
    if (isGroup) {
      query = FirebaseFirestore.instance.collection('groups').doc(_groupId).collection('group_products');
    } else {
      query = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('my_products');
    }

    // ★ カテゴリフィルター：選ばれたジャンルで絞り込む
    if (_selectedCategoryIndex != 0) {
      query = query.where('genre', isEqualTo: _categories[_selectedCategoryIndex]);
    }

    query = query.orderBy('purchaseDate', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('エラー: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Text('${_categories[_selectedCategoryIndex]} の商品はありません'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String name = data['name'] ?? '未設定';
            final Timestamp? ts = data['purchaseDate'];
            final String dateStr = ts != null ? DateFormat('MM/dd').format(ts.toDate()) : '--/--';
            final String genre = data['genre'] ?? 'その他'; // ジャンルの確認用

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black12, width: 0.5),
              ),
              child: ListTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('購入日: $dateStr  カテゴリ: $genre'),
                trailing: Icon(Icons.chevron_right, color: activeColor),
              ),
            );
          },
        );
      },
    );
  }
}