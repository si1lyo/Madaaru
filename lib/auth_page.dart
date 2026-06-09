import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // ログインか新規登録かを切り替える

  // ログイン・登録処理
  Future<void> _authenticate() async {
    try {
      if (_isLogin) {
        // ログイン
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // 新規登録
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      // エラーが起きたらダイアログを出す
      showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text(e.message ?? 'エラーが発生しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'ログイン' : '新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'メールアドレス')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'パスワード'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F624C), foregroundColor: Colors.white),
              onPressed: _authenticate,
              child: Text(_isLogin ? 'ログイン' : '登録する'),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'アカウント作成はこちら' : 'ログインはこちら'),
            ),
          ],
        ),
      ),
    );
  }
}