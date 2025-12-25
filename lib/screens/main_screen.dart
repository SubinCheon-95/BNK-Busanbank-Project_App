import 'package:flutter/material.dart';
import 'package:tkbank/screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/product/product_main_screen.dart';
import 'package:tkbank/main.dart';  // HomeScreen

class MainScreen extends StatefulWidget {
  final String baseUrl;

  const MainScreen({super.key, required this.baseUrl});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 👇 각 탭에 해당하는 화면들
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(baseUrl: widget.baseUrl),      // 0: 홈
      ProductMainScreen(baseUrl: widget.baseUrl), // 1: 상품
      _SearchPlaceholder(),                      // 2: 검색 (준비중)
      GameMenuScreen(baseUrl: widget.baseUrl),   // 3: 게임
      _MenuPlaceholder(),                        // 4: 전체 (또는 홈의 메뉴)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 75 + MediaQuery.of(context).padding.bottom,  // 👈 Container + 안전 영역!
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,

          // 색상 설정
          selectedItemColor: const Color(0xFF6A1B9A),
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.transparent,  // 👈 투명으로!
          elevation: 0,  // 👈 0으로!

          // 폰트 크기
          selectedFontSize: 16,
          unselectedFontSize: 16,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: '상품',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: '검색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports),
              label: '게임',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: '전체',
            ),
          ],
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }
}

// 임시 검색 화면
class _SearchPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,  // 뒤로가기 버튼 제거
      ),
      body: const Center(
        child: Text(
          '검색 기능 준비 중입니다',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// 임시 전체 메뉴 화면
class _MenuPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          '전체 메뉴',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}