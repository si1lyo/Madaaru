
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class AnalysisAlgorithmPage extends StatefulWidget {
  const AnalysisAlgorithmPage({super.key});

  @override
  State<AnalysisAlgorithmPage> createState() => _AnalysisAlgorithmPageState();
}

class _AnalysisAlgorithmPageState extends State<AnalysisAlgorithmPage> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ""; // 検索ワードを保持

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 周期設定を更新する処理
  Future<void> _updateCycle(String type, int newCycle) async {
    if (user == null) return;
    
    final batch = FirebaseFirestore.instance.batch();
    
    // typeが「その他の商品」の場合は、DB上の空文字またはnullのものを対象にする
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('my_products');

    if (type == 'その他の商品') {
      // typeフィールドが存在しない、または空文字のものを検索（設計に合わせて調整が必要な場合があります）
      final snapshots = await query.get();
      for (var doc in snapshots.docs) {
        final d = doc.data() as Map<String, dynamic>;
        if (d['type'] == null || d['type'] == "") {
          batch.update(doc.reference, {'cycle': newCycle});
        }
      }
    } else {
      final snapshots = await query.where('type', isEqualTo: type).get();
      for (var doc in snapshots.docs) {
        batch.update(doc.reference, {'cycle': newCycle});
      }
    }
    
    await batch.commit();
  }

  void _showDetailDialog(String type, int currentCycle, List<Map<String, dynamic>> history) {
    final controller = TextEditingController(text: currentCycle.toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$type の分析・設定', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kDarkGreen)),
            const SizedBox(height: 20),
            const Text('購入履歴', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final ts = history[index]['purchaseDate'];
                  final dateStr = ts != null ? DateFormat('yyyy/MM/dd').format((ts as Timestamp).toDate()) : '日付なし';
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 18),
                    title: Text(dateStr),
                    subtitle: Text(history[index]['name'] ?? '商品名なし'),
                  );
                },
              ),
            ),
            const Divider(),
            const Text('購入周期設定（日）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '例：14',
                      border: OutlineInputBorder(),
                      suffixText: '日',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final val = int.tryParse(controller.text);
                    if (val != null) {
                      _updateCycle(type, val);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkGreen,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  child: const Text('保存', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text('ログインが必要です')));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('購入周期設定'),
        backgroundColor: Colors.white,
        foregroundColor: kDarkGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 検索バー ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'ジャンル（牛乳、洗剤など）を検索',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('my_products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // データのグループ化
                Map<String, List<Map<String, dynamic>>> groupedItems = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String type = data['type']?.toString().trim() ?? "";
                  if (type.isEmpty) type = 'その他の商品'; // 未分類のラベル付け

                  if (!groupedItems.containsKey(type)) groupedItems[type] = [];
                  groupedItems[type]!.add(data);
                }

                // 表示用のリスト作成（ソートと検索フィルタリング）
                List<String> types = groupedItems.keys.toList();

                // ソート：その他の商品を一番上に、それ以外は名前順
                types.sort((a, b) {
                  if (a == 'その他の商品') return -1;
                  if (b == 'その他の商品') return 1;
                  return a.compareTo(b);
                });

                // 検索キーワードでフィルタリング
                if (_searchQuery.isNotEmpty) {
                  types = types.where((t) => t.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }

                if (types.isEmpty) {
                  return const Center(child: Text('該当する項目が見つかりません'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: types.length,
                  itemBuilder: (context, index) {
                    final type = types[index];
                    final items = groupedItems[type]!;
                    final int cycle = items.first['cycle'] ?? 0;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: type == 'その他の商品' ? Colors.grey : Colors.orange,
                          child: const Icon(Icons.analytics, color: Colors.white, size: 20),
                        ),
                        title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('データ件数: ${items.length}件'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$cycle 日', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => _showDetailDialog(type, cycle, items),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}