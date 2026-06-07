import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart'; // 1. これを追加

class GeneralPage extends StatefulWidget {
  const GeneralPage({super.key});

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  // --- その場で変更するための状態（変数） ---
  // _isDarkMode 変数は不要になったので削除しました（AdaptiveThemeが管理するため）
  bool _isVibrationOn = true;    // スキャン時の振動

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('一般設定'),
      ),
      body: ListView(
        children: [
          // 【デザイン設定】
          const _SectionHeader(title: 'デザイン'),
          SwitchListTile(
            // 2. 現在のモードがダークかどうかでアイコンを変える
            secondary: Icon(
              AdaptiveTheme.of(context).mode.isDark 
                  ? Icons.dark_mode 
                  : Icons.light_mode
            ),
            title: const Text('ダークモード'),
            subtitle: Text(
              AdaptiveTheme.of(context).mode.isDark ? '背景を暗くします' : '背景を明るくします'
            ),
            // 3. 値を AdaptiveTheme から直接取得する
            value: AdaptiveTheme.of(context).mode.isDark,
            onChanged: (bool value) {
              // 4. スイッチを切り替えた時の処理
              if (value) {
                AdaptiveTheme.of(context).setDark(); // ダークモードにする
              } else {
                AdaptiveTheme.of(context).setLight(); // ライトモードにする
              }
              // 画面を更新
              setState(() {});
            },
          ),
          const Divider(),

          // 【スキャン時の挙動】
          const _SectionHeader(title: 'スキャン時の挙動'),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('スキャン成功時の振動'),
            subtitle: Text(_isVibrationOn ? '振動する' : '振動しない'),
            value: _isVibrationOn,
            onChanged: (bool value) {
              setState(() {
                _isVibrationOn = value;
              });
            },
          ),
          const Divider(),

          // 【サポート・利用規約（以下略）】
          const _SectionHeader(title: 'サポート'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('ヘルプ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

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