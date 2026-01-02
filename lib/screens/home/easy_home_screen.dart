import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/theme/app_colors.dart';
import 'package:tkbank/widgets/easy_menu_bar.dart';
import 'package:tkbank/core/menu/main_menu_config.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/services/token_storage_service.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/screens/product/product_main_screen.dart';
import 'package:tkbank/screens/product/interest_calculator_screen.dart';
import 'package:tkbank/screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';
import 'package:tkbank/screens/product/news_analysis_screen.dart';
import 'package:tkbank/screens/member/point_history_screen.dart';
import 'package:tkbank/screens/event/seed_event_screen.dart';
import 'package:tkbank/screens/member/security_center_screen.dart';
import 'package:tkbank/screens/my_page/my_page_screen.dart';
import 'package:tkbank/screens/camera/vision_test_screen.dart';
import 'ar_home_screen.dart';

class EasyHomeScreen extends StatefulWidget {
  final String baseUrl;

  const EasyHomeScreen({super.key, required this.baseUrl});

  @override
  State<EasyHomeScreen> createState() => _EasyHomeScreenState();
}

class _EasyHomeScreenState extends State<EasyHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 200) {
      if (!_showTopButton) {
        setState(() => _showTopButton = true);
      }
    } else {
      if (_showTopButton) {
        setState(() => _showTopButton = false);
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _logout(BuildContext context) async {
    await TokenStorageService().deleteToken();
    if (context.mounted) {
      final authProvider = context.read<AuthProvider>();
      authProvider.logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isLoggedIn),
              const SizedBox(height: 20),
              _buildGreeting(context, authProvider, isLoggedIn),
              const SizedBox(height: 30),
              EasyMenuBar(
                menuType: MainMenuType.easy,
                baseUrl: widget.baseUrl,
              ),
              const SizedBox(height: 50),
              _buildMenuList(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: _showTopButton
          ? Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: _scrollToTop,
          icon: const Icon(
            Icons.keyboard_double_arrow_up,
            color: AppColors.white,
            size: 32,
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/TKBank_logo.png',
            height: 25,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'TK 딸깍은행',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _showSearchModal(context),
                icon: const Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 2),
              if (!isLoggedIn)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(
                    Icons.login,
                    color: AppColors.primary,
                    size: 28,
                  ),
                )
              else
                IconButton(
                  onPressed: () => _logout(context),
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.gray4,
                    size: 28,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 검색 모달 - 새로운 위젯 사용
  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchModalContent(baseUrl: widget.baseUrl),
    );
  }

  Widget _buildGreeting(BuildContext context, AuthProvider authProvider, bool isLoggedIn) {
    String greeting1;
    String greeting2;

    if (isLoggedIn) {
      final userName = authProvider.userName ?? '고객';
      greeting1 = '$userName님,';
      greeting2 = '오늘도 행복하세요!';
    } else {
      greeting1 = '안녕하세요!';
      greeting2 = '무엇이 필요하신가요?';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting1,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                    height: 1.4,
                  ),
                ),
                Text(
                  greeting2,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ArHomeScreen(baseUrl: widget.baseUrl),
                ),
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/images/penguinman.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.account_circle,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '메뉴 목록',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _menuListItem(context, '금융상품 보기', Icons.shopping_bag, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductMainScreen(baseUrl: widget.baseUrl),
              ),
            );
          }),
          _menuListItem(context, '금리계산기', Icons.calculate, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InterestCalculatorScreen(),
              ),
            );
          }),
          _menuListItem(context, '금융게임', Icons.games, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameMenuScreen(baseUrl: widget.baseUrl),
              ),
            );
          }),
          _menuListItem(context, 'AI 뉴스', Icons.auto_awesome, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewsAnalysisMainScreen(baseUrl: widget.baseUrl),
              ),
            );
          }),
          _menuListItem(context, '포인트 이력', Icons.stars, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PointHistoryScreen(baseUrl: widget.baseUrl),
              ),
            );
          }),
          _menuListItem(context, '고객센터', Icons.support_agent, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerSupportScreen(),
              ),
            );
          }),
          if (isLoggedIn) ...[
            _menuListItem(context, '금열매 이벤트', Icons.eco, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeedEventScreen()),
              );
            }),
            _menuListItem(context, '인증센터', Icons.lock_outline, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecurityCenterScreen()),
              );
            }),
            _menuListItem(context, '마이페이지', Icons.person, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPageScreen()),
              );
            }),
          ],
          _menuListItem(context, '로고 인증 이벤트', Icons.camera_alt, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VisionTestScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _menuListItem(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gray4),
            ],
          ),
        ),
      ),
    );
  }
}

// 검색 모달 위젯
class _SearchModalContent extends StatefulWidget {
  final String baseUrl;

  const _SearchModalContent({required this.baseUrl});

  @override
  State<_SearchModalContent> createState() => _SearchModalContentState();
}

class _SearchModalContentState extends State<_SearchModalContent> {
  final TextEditingController _searchController = TextEditingController();
  List<_SearchMenuItem> _searchResults = [];

  final List<_SearchMenuItem> _allMenus = [
    _SearchMenuItem(
      label: '금융상품 보기',
      icon: Icons.shopping_bag,
      keywords: ['금융', '상품', '보기', '예금', '적금', '대출'],
    ),
    _SearchMenuItem(
      label: '금리계산기',
      icon: Icons.calculate,
      keywords: ['금리', '계산기', '이자', '계산'],
    ),
    _SearchMenuItem(
      label: '금융게임',
      icon: Icons.games,
      keywords: ['금융', '게임', '골드', '비트코인', '오일', 'BTC'],
    ),
    _SearchMenuItem(
      label: 'AI 뉴스',
      icon: Icons.auto_awesome,
      keywords: ['AI', '뉴스', '분석', '기사', '인공지능'],
    ),
    _SearchMenuItem(
      label: '포인트 이력',
      icon: Icons.stars,
      keywords: ['포인트', '이력', '내역', '적립'],
    ),
    _SearchMenuItem(
      label: '고객센터',
      icon: Icons.support_agent,
      keywords: ['고객', '센터', '문의', '상담', 'CS'],
    ),
    _SearchMenuItem(
      label: '금열매 이벤트',
      icon: Icons.eco,
      keywords: ['금열매', '이벤트', '나무', '열매'],
      requiresLogin: true,
    ),
    _SearchMenuItem(
      label: '인증센터',
      icon: Icons.lock_outline,
      keywords: ['인증', '센터', '보안', '비밀번호'],
      requiresLogin: true,
    ),
    _SearchMenuItem(
      label: '마이페이지',
      icon: Icons.person,
      keywords: ['마이', '페이지', '내정보', '프로필'],
      requiresLogin: true,
    ),
    _SearchMenuItem(
      label: '로고 인증 이벤트',
      icon: Icons.camera_alt,
      keywords: ['로고', '인증', '이벤트', '카메라'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _searchResults = _allMenus.where((menu) {
        if (menu.label.toLowerCase().contains(lowerQuery)) return true;
        return menu.keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }

  void _navigateToMenu(_SearchMenuItem menu) {
    final authProvider = context.read<AuthProvider>();

    if (menu.requiresLogin && !authProvider.isLoggedIn) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요한 서비스입니다')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Navigator.pop(context);

    switch (menu.label) {
      case '금융상품 보기':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductMainScreen(baseUrl: widget.baseUrl)));
        break;
      case '금리계산기':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestCalculatorScreen()));
        break;
      case '금융게임':
        Navigator.push(context, MaterialPageRoute(builder: (_) => GameMenuScreen(baseUrl: widget.baseUrl)));
        break;
      case 'AI 뉴스':
        Navigator.push(context, MaterialPageRoute(builder: (_) => NewsAnalysisMainScreen(baseUrl: widget.baseUrl)));
        break;
      case '포인트 이력':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PointHistoryScreen(baseUrl: widget.baseUrl)));
        break;
      case '고객센터':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSupportScreen()));
        break;
      case '금열매 이벤트':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SeedEventScreen()));
        break;
      case '인증센터':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityCenterScreen()));
        break;
      case '마이페이지':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPageScreen()));
        break;
      case '로고 인증 이벤트':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VisionTestScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '필요한 메뉴를 검색하세요',
                hintStyle: TextStyle(color: AppColors.gray4),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.gray4),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
                    : null,
                filled: true,
                fillColor: AppColors.gray2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: _performSearch,
            ),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: _searchController.text.isEmpty ? _buildRecommendations() : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text(
          '추천 검색어',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.black),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _searchChip('금리계산기'),
            _searchChip('AI 뉴스'),
            _searchChip('금융게임'),
            _searchChip('골드'),
            _searchChip('비트코인'),
            _searchChip('예금'),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.gray4),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray4),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final menu = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _navigateToMenu(menu),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      menu.icon,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      menu.label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.gray4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _searchChip(String label) {
    return InkWell(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gray2,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gray5),
        ),
      ),
    );
  }
}

// 검색 메뉴 아이템 클래스 (파일 맨 아래)
class _SearchMenuItem {
  final String label;
  final IconData icon;
  final List<String> keywords;
  final bool requiresLogin;

  _SearchMenuItem({
    required this.label,
    required this.icon,
    required this.keywords,
    this.requiresLogin = false,
  });
}