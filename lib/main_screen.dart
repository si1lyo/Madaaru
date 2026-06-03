import 'package:flutter/material.dart';
import 'home_page.dart';
import 'calender_page.dart';
import 'camera_page.dart';
import 'setting_page.dart';
import 'notification_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

final Color themeColor = const Color(0xFF0F624C);

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const CalendarPage(),
    const CameraPage(),
    const SettingPage(),
    const NotificationPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () {
            setState(() => _currentIndex = 2);
          },

          backgroundColor: const Color(0xFF0F624C),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),

      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
              icon: Icon(
                Icons.calendar_month_outlined,
                color: _currentIndex == 1 ? themeColor : Colors.grey,
              ),
              onPressed: () => setState(() => _currentIndex = 1),
            ),

            IconButton(
              icon: Icon(
                Icons.home_outlined,
                // 選ばれているときはテーマカラー（緑）、そうじゃないときはグレーにする
                color: _currentIndex == 0 ? themeColor : Colors.grey,
              ),
              onPressed: () {
                // タップされたら現在の番号を「0」に更新して画面を再描画する
                setState(() => _currentIndex = 0);
              },
            ),

            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: _currentIndex == 3 ? themeColor : Colors.grey,
              ),
              onPressed: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}
