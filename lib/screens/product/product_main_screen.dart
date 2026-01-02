import 'package:flutter/material.dart';
import 'package:tkbank/theme/app_colors.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'product_category_list_screen.dart';
import 'news_analysis_screen.dart';

class ProductMainScreen extends StatefulWidget {
  const ProductMainScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<ProductMainScreen> createState() => _ProductMainScreenState();
}

class _ProductMainScreenState extends State<ProductMainScreen> {
  late ProductService _service;

  @override
  void initState() {
    super.initState();
    _service = ProductService(widget.baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // 이미지+카테고리 헤더
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none, // 넘치는 부분도 보이게!
              children: [

                // 이미지
                Container(
                  width: double.infinity,
                  height: 300,
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
                        // 뒤로가기
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

                        // 타이틀
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
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
                      ],
                    ),
                  ),
                ),

                // 카테고리 헤더
                Positioned(
                  bottom: -40,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.gray1,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                    child: const Text(
                      '카테고리별 상품',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 겹치는 여백
          const SliverToBoxAdapter(
            child: SizedBox(height: 50),
          ),

          // 카테고리 리스트
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _buildCategoryItem(context, _categories[index]);
                },
                childCount: _categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리 목록
  final List<Map<String, dynamic>> _categories = const [
    {
      'name': '입출금자유',
      'code': 'freedepwith',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFF4CAF50),
    },
    {
      'name': '목돈만들기',
      'code': 'lumpsum',
      'icon': Icons.savings,
      'color': Color(0xFFFF9800),
    },
    {
      'name': '목돈굴리기',
      'code': 'lumprolling',
      'icon': Icons.trending_up,
      'color': Color(0xFF2196F3),
    },
    {
      'name': '주택마련',
      'code': 'housing',
      'icon': Icons.home,
      'color': Color(0xFF9C27B0),
    },
    {
      'name': '스마트금융전용',
      'code': 'smartfinance',
      'icon': Icons.phone_android,
      'color': Color(0xFFE91E63),
    },
    {
      'name': '미래테크',
      'code': 'future',
      'icon': Icons.rocket_launch,
      'color': Color(0xFF00BCD4),
    },
    {
      'name': '자산전문예금',
      'code': 'three',
      'icon': Icons.diamond,
      'color': Color(0xFFFF5722),
    },
  ];

  // 카테고리 UI
  Widget _buildCategoryItem(BuildContext context, Map<String, dynamic> category) {
    return Container(
      height: 85,
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
          onTap: () {
            final name = category['name'] as String;

            if (name == '미래테크') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewsAnalysisMainScreen(baseUrl: widget.baseUrl),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductCategoryListScreen(
                  baseUrl: widget.baseUrl,
                  categoryName: name,
                  categoryCode: category['code'] as String,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(5),
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
  }
}