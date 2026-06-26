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

// ── マイリスト ──────────────────────────────────────────────────
class _MyList extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;
  final Color activeColor;

  const _MyList({
    required this.searchQuery,
    required this.selectedCategory,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('my_products')
          .orderBy('purchaseDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kDarkGreen),
          );
        }

        var docs = snapshot.data?.docs ?? [];

        // 検索とカテゴリでフィルタリング
        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final name = ((doc.data() as Map)['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();
        }
        if (selectedCategory != 'すべて') {
          docs = docs.where((doc) => (doc.data() as Map)['genre'] == selectedCategory).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text('商品がありません', style: TextStyle(color: Colors.grey)));
        }

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
              isOut: data['isOut'] as bool? ?? false, // 在庫なしフラグを取得
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

  const _GroupList({
    required this.groupId,
    required this.searchQuery,
    required this.selectedCategory,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('group_products')
          .orderBy('purchaseDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kDarkGreen));
        }

        var docs = snapshot.data?.docs ?? [];

        if (searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final name = ((doc.data() as Map)['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();
        }
        if (selectedCategory != 'すべて') {
          docs = docs.where((doc) => (doc.data() as Map)['genre'] == selectedCategory).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text('グループに商品がありません', style: TextStyle(color: Colors.grey)));
        }

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
              isOut: data['isOut'] as bool? ?? false, // 在庫なしフラグ
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
  final bool isOut; // 在庫切れフラグ
  final Color activeColor;
  final bool isGroup;
  final String? groupId;

  const _ProductCard({
    required this.docId,
    required this.name,
    required this.genre,
    this.price = 0,
    this.purchaseDate,
    this.icon = '',
    required this.isOut,
    required this.activeColor,
    required this.isGroup,
    this.groupId,
  });

  // Firestoreの参照（住所）を取得するヘルパー
  DocumentReference get _docRef {
    return isGroup
        ? FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('group_products')
            .doc(docId)
        : FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('my_products')
            .doc(docId);
  }

  // 「消費（在庫なし）」にする処理
  Future<void> _markAsOut(BuildContext context) async {
    try {
      await _docRef.update({
        'isOut': true,
        'outDate': Timestamp.now(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name を消費しました'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更新に失敗しました')));
      }
    }
  }

  // ★「消費を取り消す」処理（確認ダイアログ付き）
  Future<void> _undoMarkAsOut(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('消費の取り消し'),
        content: Text('$name を「在庫あり」の状態に戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('はい'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('いいえ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _docRef.update({
          'isOut': false,
          'outDate': FieldValue.delete(), // 消費日データを消去
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('在庫ありに戻しました'), duration: Duration(seconds: 1)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更新に失敗しました')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.of(context).surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(docId: docId, isGroup: isGroup, groupId: groupId),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // アイコン部分
              Opacity(
                opacity: isOut ? 0.4 : 1.0,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: () {
                      final code = int.tryParse(icon);
                      return Icon(
                        code != null ? IconData(code, fontFamily: 'MaterialIcons') : Icons.inventory_2_outlined,
                        color: activeColor,
                        size: 22,
                      );
                    }(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 商品情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isOut ? Colors.grey : Colors.black87,
                        decoration: isOut ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOut ? '在庫なし' : genre,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOut ? Colors.red.withOpacity(0.6) : Colors.grey[500],
                        fontWeight: isOut ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // ボタン部分
              if (!isOut)
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _markAsOut(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('消費', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                // ★ 改良：タップできる「消費済み」ラベル
                InkWell(
                  onTap: () => _undoMarkAsOut(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      '消費済み',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}