import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart'; // これが必要
import 'main_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. 追加
import 'firebase_options.dart'; // 2. 追加（自動生成されたファイル）

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★ ここに Firebase の初期化を追加！
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 前回の保存設定を読み込む（以前からあるコード）
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  
  runApp(MyApp(savedThemeMode: savedThemeMode));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  const MyApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      // ライトモードの設定
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF0F624C),
      ),
      // ダークモードの設定
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF0F624C),
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      
      // ここで全体の見た目を一気に変える指示を出す
      builder: (theme, darkTheme) => MaterialApp(
        title: 'まだある？',
        debugShowCheckedModeBanner: false,
        theme: theme,      // builderから渡されたテーマを適用
        darkTheme: darkTheme, // builderから渡されたダークテーマを適用
        home: const MainScreen(),
      ),
    );
  }
}