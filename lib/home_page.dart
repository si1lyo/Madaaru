import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'product_detail_page.dart';

class HomePage extends StatefulWidget {
  final String searchQuery;
  const HomePage({super.key, this.searchQuery = ''});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  int _selectedCategoryIndex = 0;
  String? _groupName;
  String? _groupId;

  static const _categories = ['すべて', '食品', '日用品', 'その他'];

  Color get activeColor => kDarkGreen;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (!_mainTabController.indexIsChanging) setState(() {});
    });
    _fetchGroupInfo();
  }

  Future<void> _fetchGroupInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    final gid = userDoc.data()?['groupId'] as String?;
    if (gid != null && gid.isNotEmpty) {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups').doc(gid).get();
      if (mounted) {
        setState(() {
          _groupId = gid;
          _groupName = groupDoc.data()?['groupName'] as String?;
        });
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: _buildTitleToggle(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: kDarkGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecentlyConsumedPage(
                    isGroup: _mainTabController.index == 1,
                    groupId: _groupId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildCategoryBar(),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _MyList(
            searchQuery: widget.searchQuery,
            selectedCategory: _categories[_selectedCategoryIndex],
            activeColor: activeColor,
          ),
          _groupId != null
              ? _GroupList(
                  groupId: _groupId!,
                  searchQuery: widget.searchQuery,
                  selectedCategory: _categories[_selectedCategoryIndex],
                  activeColor: activeColor,
                )
              : const Center(
                  child: Text(
                    'グループに所属していません',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTitleToggle() {
    final isGroup = _mainTabController.index == 1;
    final surfaceColor = AppColors.of(context).surface;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem('マイリスト', !isGroup, () => _mainTabController.animateTo(0)),
          if (_groupName != null)
            _toggleItem(
              _groupName!,
              isGroup,
              () => _mainTabController.animateTo(1),
            ),
        ],
      ),
    );
  }

  Widget _toggleItem(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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

  Widget _buildCategoryBar() {
    return Container(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? activeColor : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── 履歴ページ ──────────────────────────────────────────────
class RecentlyConsumedPage extends StatelessWidget {
  final bool isGroup;
  final String? groupId;

  const RecentlyConsumedPage({super.key, required this.isGroup, this.groupId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    // 住所の決定
    final CollectionReference collection = isGroup
        ? FirebaseFirestore.instance.collection('groups').doc(groupId).collection('group_products')
        : FirebaseFirestore.instance.collection('users').doc(user.uid).collection('my_products');

    return Scaffold(
      appBar: AppBar(
        title: Text(isGroup ? 'グループの消費履歴' : '個人の消費履歴', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: kDarkGreen,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ★ シンプルに「isOutがtrueのもの」だけを持ってくる（並び替えはここではしない）
        stream: collection.where('isOut', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('エラーが発生しました\n${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('最近消費した商品はありません', style: TextStyle(color: Colors.grey)));
          }

          // ★ アプリ側で日付順に並び替える（データが壊れていてもエラーにならない工夫）
          final sortedDocs = List.from(docs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final Timestamp? aTime = aData['outDate'] ?? aData['purchaseDate']; // outDateがなければ購入日で代用
            final Timestamp? bTime = bData['outDate'] ?? bData['purchaseDate'];
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // 新しい順
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['outDate'] as Timestamp?)?.toDate();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.history_toggle_off, color: Colors.orange),
                  title: Text(data['name'] ?? '名前なし', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(date != null 
                    ? '${DateFormat('MM/dd HH:mm').format(date)} に消費' 
                    : '消費日の記録なし'),
                  trailing: TextButton(
                    onPressed: () async {
                      // 「在庫あり」に戻す処理
                      await doc.reference.update({
                        'isOut': false, 
                        'outDate': FieldValue.delete()
                      });
                    },
                    child: const Text('戻す'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// ── マイリスト ──────────────────────────────────────────────────
class _MyList extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;
  final Color activeColor;

  const _MyList({required this.searchQuery, required this.selectedCategory, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(user.uid).collection('my_products')
          .orderBy('purchaseDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data?.docs ?? [];

        // 在庫あり（isOutがtrueでないもの）のみを抽出
        // ※ 複合インデックスエラーを避けるため、一旦アプリ側でフィルタリングします
        docs = docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['isOut'] != true;
        }).toList();

        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) => (doc['name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
        }
        if (selectedCategory != 'すべて') {
          docs = docs.where((doc) => doc['genre'] == selectedCategory).toList();
        }

        if (docs.isEmpty) return const Center(child: Text('商品がありません', style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _ProductCard(
              docId: docs[i].id,
              name: data['name'] ?? '',
              genre: data['genre'] ?? '',
              price: (data['price'] as num?)?.toDouble() ?? 0,
              purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
              icon: data['icon'] as String? ?? '',
              isOut: false,
              activeColor: activeColor,
              isGroup: false,
            );
          },
        );
      },
    );
  }
}

// ── グループリスト ────────────────────────────────────────────
class _GroupList extends StatelessWidget {
  final String groupId;
  final String searchQuery;
  final String selectedCategory;
  final Color activeColor;

  const _GroupList({required this.groupId, required this.searchQuery, required this.selectedCategory, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups').doc(groupId).collection('group_products')
          .orderBy('purchaseDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data?.docs ?? [];
        docs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['isOut'] != true).toList();

        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) => (doc['name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
        }
        if (selectedCategory != 'すべて') {
          docs = docs.where((doc) => doc['genre'] == selectedCategory).toList();
        }

        if (docs.isEmpty) return const Center(child: Text('グループに商品がありません', style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _ProductCard(
              docId: docs[i].id,
              name: data['name'] ?? '',
              genre: data['genre'] ?? '',
              price: (data['price'] as num?)?.toDouble() ?? 0,
              purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
              icon: data['icon'] as String? ?? '',
              isOut: false,
              activeColor: activeColor,
              isGroup: true,
              groupId: groupId,
            );
          },
        );
      },
    );
  }
}

// ── 商品カード ────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final String docId;
  final String name;
  final String genre;
  final double price;
  final DateTime? purchaseDate;
  final String icon;
  final bool isOut; 
  final Color activeColor;
  final bool isGroup;
  final String? groupId;

  const _ProductCard({required this.docId, required this.name, required this.genre, this.price = 0, this.purchaseDate, this.icon = '', required this.isOut, required this.activeColor, required this.isGroup, this.groupId});

  DocumentReference get _docRef {
    return isGroup
        ? FirebaseFirestore.instance.collection('groups').doc(groupId).collection('group_products').doc(docId)
        : FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('my_products').doc(docId);
  }

  Future<void> _markAsOut(BuildContext context) async {
    try {
      await _docRef.update({'isOut': true, 'outDate': Timestamp.now()});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _undoMarkAsOut(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('消費の取り消し'),
        content: Text('$name を戻しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('はい')),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('いいえ')),
        ],
      ),
    );
    if (confirm == true) {
      await _docRef.update({'isOut': false, 'outDate': FieldValue.delete()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.of(context).surface;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(docId: docId, isGroup: isGroup, groupId: groupId))),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: activeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Icon(Icons.inventory_2_outlined, color: activeColor, size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, decoration: isOut ? TextDecoration.lineThrough : null)),
                Text(genre, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
              if (!isOut)
                ElevatedButton(
                  onPressed: () => _markAsOut(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('消費', style: TextStyle(fontSize: 12)),
                )
              else
                TextButton(onPressed: () => _undoMarkAsOut(context), child: const Text('消費済み', style: TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }
}