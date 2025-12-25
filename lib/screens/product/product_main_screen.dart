import 'package:flutter/material.dart';
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ✅ 풀스크린 Hero Section
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // 배경 이미지 (풀스크린)
                Container(
                  width: double.infinity,
                  height: 500,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/finance_main.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: SafeArea(  // 👈 상단 노치 영역 확보
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),

                          // 타이틀 (중앙)
                          const Text(
                            '당신의 재무 목표를\n실현하세요',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // 서브타이틀 (중앙)
                          const Text(
                            '높은 금리와 다양한 혜택으로\n더 나은 미래를 준비하세요',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 👈 뒤로가기 버튼 (왼쪽 상단)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ 카테고리별 상품
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        '카테고리별 상품',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {
        'name': '입출금자유',
        'code': 'freedepwith',
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFF4CAF50),
      },
      {
        'name': '목돈만들기',
        'code': 'lumpsum',
        'icon': Icons.savings,
        'color': const Color(0xFFFF9800),
      },
      {
        'name': '목돈굴리기',
        'code': 'lumprolling',
        'icon': Icons.trending_up,
        'color': const Color(0xFF2196F3),
      },
      {
        'name': '주택마련',
        'code': 'housing',
        'icon': Icons.home,
        'color': const Color(0xFF9C27B0),
      },
      {
        'name': '스마트금융전용',
        'code': 'smartfinance',
        'icon': Icons.phone_android,
        'color': const Color(0xFFE91E63),
      },
      {
        'name': '미래테크',
        'code': 'future',
        'icon': Icons.rocket_launch,
        'color': const Color(0xFF00BCD4),
      },
      {
        'name': '자산전문예금',
        'code': 'three',
        'icon': Icons.diamond,
        'color': const Color(0xFFFF5722),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(
          context: context,
          title: category['name'] as String,
          icon: category['icon'] as IconData,
          color: category['color'] as Color,
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
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ 배경 패턴 페인터
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 10; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3 + i * 30),
        20 + i * 10,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}