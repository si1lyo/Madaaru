import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // --- 通知のオンオフ状態を管理する変数 ---
  bool _isAllNotificationsEnabled = true; // 通知全般
  bool _stockAlert = true;                // 在庫不足通知
  bool _analysisAlert = true;             // 分析通知

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
      ),
      body: ListView(
        children: [
          // 【メインスイッチ：通知全般】
          const _SectionHeader(title: '全般設定'),
          SwitchListTile(
            secondary: Icon(
              _isAllNotificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: _isAllNotificationsEnabled ? Colors.blue : Colors.grey,
            ),
            title: const Text('通知全般'),
            subtitle: const Text('アプリからのすべての通知をコントロールします'),
            value: _isAllNotificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _isAllNotificationsEnabled = value;
                // 全般がオフになったら、個別の設定も連動させる（お好みで）
                if (!value) {
                  _stockAlert = false;
                  _analysisAlert = false;
                }
              });
            },
          ),
          
          const Divider(),

          // 【個別設定】
          const _SectionHeader(title: '項目別の通知'),
          
          // 通知全般がオフの時は、個別設定を「無効（グレーアウト）」にする仕組み
          SwitchListTile(
            title: const Text('在庫不足アラート'),
            subtitle: const Text('商品の残りが少なくなった時'),
            value: _stockAlert,
            // _isAllNotificationsEnabled が false なら onChanged を null にして無効化
            onChanged: _isAllNotificationsEnabled ? (bool value) {
              setState(() {
                _stockAlert = value;
              });
            } : null,
          ),
          
          SwitchListTile(
            title: const Text('購入周期の予測通知'),
            subtitle: const Text('分析による買い時のお知らせ'),
            value: _analysisAlert,
            onChanged: _isAllNotificationsEnabled ? (bool value) {
              setState(() {
                _analysisAlert = value;
              });
            } : null,
          ),
        ],
      ),
    );
  }
}

// セクション区切り用のパーツ
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}