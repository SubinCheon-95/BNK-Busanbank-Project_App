import 'package:flutter/material.dart';
import 'package:tkbank/models/product.dart';
import 'package:tkbank/services/product_service.dart';
import 'product_detail_screen.dart';
import 'interest_calculator_screen.dart';
import 'news_analysis_screen.dart';
import 'package:tkbank/theme/app_colors.dart';

class ProductMainScreen extends StatefulWidget {
  const ProductMainScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<ProductMainScreen> createState() => _ProductMainScreenState();
}

class _ProductMainScreenState extends State<ProductMainScreen>
    with SingleTickerProviderStateMixin {
  late ProductService _service;
  late TabController _tabController;
  ScrollController? _currentScrollController;

  // 탭바용 카테고리
  final List<Map<String, dynamic>> _categories = [
    {'name': '전체', 'code': 'all'},
    {
      'name': '입출금자유',
      'code': 'freedepwith',
      'icon': Icons.account_balance_wallet,
      'color': AppColors.yellowGreen
    },
    {
      'name': '목돈만들기',
      'code': 'lumpsum',
      'icon': Icons.savings,
      'color': AppColors.yellow
    },
    {
      'name': '목돈굴리기',
      'code': 'lumprolling',
      'icon': Icons.trending_up,
      'color': AppColors.red
    },
    {
      'name': '주택마련',
      'code': 'housing',
      'icon': Icons.home,
      'color': AppColors.green
    },
    {
      'name': '스마트금융전용',
      'code': 'smartfinance',
      'icon': Icons.phone_android,
      'color': AppColors.pink
    },
    {
      'name': '자산전문예금',
      'code': 'three',
      'icon': Icons.diamond,
      'color': AppColors.blue
    },
  ];

  // 전체 탭 버튼용 카테고리
  final List<Map<String, dynamic>> _allCategoryButtons = [
    {
      'name': '입출금자유',
      'code': 'freedepwith',
      'icon': Icons.account_balance_wallet,
      'color': AppColors.yellowGreen
    },
    {
      'name': '목돈만들기',
      'code': 'lumpsum',
      'icon': Icons.savings,
      'color': AppColors.yellow
    },
    {
      'name': '목돈굴리기',
      'code': 'lumprolling',
      'icon': Icons.trending_up,
      'color': AppColors.red
    },
    {
      'name': '주택마련',
      'code': 'housing',
      'icon': Icons.home,
      'color': AppColors.green
    },
    {
      'name': '스마트금융전용',
      'code': 'smartfinance',
      'icon': Icons.phone_android,
      'color': AppColors.pink
    },
    {
      'name': '미래테크',
      'code': 'future',
      'icon': Icons.rocket_launch,
      'color': AppColors.primary
    },
    {
      'name': '자산전문예금',
      'code': 'three',
      'icon': Icons.diamond,
      'color': AppColors.blue
    },
  ];

  @override
  void initState() {
    super.initState();
    _service = ProductService(widget.baseUrl);
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // TOP 버튼
  void _scrollToTop() {
    _currentScrollController?.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: Column(
        children: [
          // 상단 이미지 + TabBar (고정)
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 이미지
              Container(
                width: double.infinity,
                height: screenHeight * 0.35,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/product_main.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black38,
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: AppColors.white,
                            size: 34,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.04),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '당신의 재무 목표를\n실현하세요!',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12),
                              Text(
                                '높은 금리와 다양한 혜택으로\n더 나은 미래를 준비하세요',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.white,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // TabBar 헤더
              Positioned(
                bottom: screenHeight * -0.05,
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * 0.115,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
                  decoration: const BoxDecoration(
                    color: AppColors.gray1,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    indicator: const BoxDecoration(),
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.gray4,
                    labelStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: _categories.map((cat) {
                      return Tab(text: cat['name'] as String);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          // 탭 콘텐츠 (스크롤 가능)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                final categoryCode = category['code'] as String;
                final categoryName = category['name'] as String;

                // 전체 탭
                if (categoryCode == 'all') {
                  return _CategoryButtonsTab(
                    categories: _allCategoryButtons,
                    onCategoryTap: (buttonIndex) {
                      final selectedCategory = _allCategoryButtons[buttonIndex];
                      final code = selectedCategory['code'] as String;

                      if (code == 'future') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NewsAnalysisMainScreen(baseUrl: widget.baseUrl),
                          ),
                        );
                      } else {
                        final tabIndex = _categories.indexWhere((cat) => cat['code'] == code);
                        if (tabIndex != -1) {
                          _tabController.animateTo(tabIndex);
                        }
                      }
                    },
                  );
                }

                // 나머지 탭들은 상품 리스트
                return _ProductListTab(
                  baseUrl: widget.baseUrl,
                  categoryCode: categoryCode,
                  categoryName: categoryName,
                  onScrollControllerCreated: (controller) {
                    // 현재 활성화된 탭의 스크롤 컨트롤러만 저장
                    if (_tabController.index == _categories.indexWhere((cat) => cat['code'] == categoryCode)) {
                      _currentScrollController = controller;
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),

      // FloatingActionButton
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 금리계산기 버튼
          Container(
            width: screenWidth * 0.14,
            height: screenWidth * 0.14,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InterestCalculatorScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.calculate,
                color: AppColors.white,
                size: 32,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // TOP 버튼 (항상 노출)
          Container(
            width: screenWidth * 0.14,
            height: screenWidth * 0.14,
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
          ),
        ],
      ),
    );
  }
}

class _CategoryButtonsTab extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(int) onCategoryTap;

  const _CategoryButtonsTab({
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          height: screenHeight * 0.085,
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onCategoryTap(index),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    // 아이콘
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: category['color'] as Color,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 15),

                    // 카테고리명
                    Expanded(
                      child: Text(
                        category['name'] as String,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),

                    // 화살표
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.gray4,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 상품 리스트 탭
class _ProductListTab extends StatefulWidget {
  final String baseUrl;
  final String categoryCode;
  final String categoryName;
  final Function(ScrollController)? onScrollControllerCreated;

  const _ProductListTab({
    required this.baseUrl,
    required this.categoryCode,
    required this.categoryName,
    this.onScrollControllerCreated,
  });

  @override
  State<_ProductListTab> createState() => _ProductListTabState();
}

class _ProductListTabState extends State<_ProductListTab>
    with AutomaticKeepAliveClientMixin {
  late ProductService _service;
  List<Product> _products = [];
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _service = ProductService(widget.baseUrl);
    _loadProducts();

    // 스크롤 컨트롤러 콜백
    if (widget.onScrollControllerCreated != null) {
      widget.onScrollControllerCreated!(_scrollController);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _service.fetchProductsByCategory(widget.categoryCode);

      setState(() {
        _products = products;
        _loading = false;
      });

      print('📦 ${widget.categoryName} 상품: ${products.length}개');
    } catch (e) {
      print('❌ 상품 조회 실패: $e');
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품 조회 실패: $e')),
        );
      }
    }
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _products.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox,
            size: 80,
            color: AppColors.gray3,
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.categoryName} 상품이 없습니다',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.gray3,
            ),
          ),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
        itemCount: _products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  baseUrl: widget.baseUrl,
                  product: product,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 배지
                Row(
                  children: [
                    if (product.joinTypes?.contains('MOBILE') == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '모바일',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '신상품',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 상품명
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),

                const SizedBox(height: 8),

                // 설명
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.gray5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // 금리 정보
                if (product.maturityRate > 0)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '최고 연',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray5,
                              ),
                            ),
                            Text(
                              '${_formatNumber(product.maturityRate)}%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Text(
                            '(기본 연 ${_formatNumber(product.baseRate)}%, 12개월 세전)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // 가입 방법
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (product.joinTypes?.contains('BRANCH') == true)
                      _buildJoinTypeChip('영업점 가입', Icons.store),
                    if (product.joinTypes?.contains('INTERNET') == true)
                      _buildJoinTypeChip('인터넷 가입', Icons.computer),
                    if (product.joinTypes?.contains('MOBILE') == true)
                      _buildJoinTypeChip('스마트폰 가입', Icons.smartphone),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinTypeChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gray2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray5,
            ),
          ),
        ],
      ),
    );
  }
}