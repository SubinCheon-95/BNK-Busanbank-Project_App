import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'product_list_screen.dart';

class ProductMainScreen extends StatefulWidget {
  const ProductMainScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<ProductMainScreen> createState() => _ProductMainScreenState();
}

class _ProductMainScreenState extends State<ProductMainScreen> {
  late ProductService _service;
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _service = ProductService(widget.baseUrl);
    _futureProducts = _service.fetchProducts();
  }

  List<Product> _filterByCategory(List<Product> all, String category) {
    switch (category) {
      case '예금':
        return all.where((p) => p.type == '01').toList();
      case '적금':
        return all.where((p) => p.type == '02').toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 🎨 Hero Section
          SliverToBoxAdapter(
            child: Container(
              height: 380,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: Stack(
                children: [
                  // 배경 아이콘
                  ...List.generate(15, (index) {
                    return Positioned(
                      left: (index * 80.0) % 400,
                      top: (index * 60.0) % 350,
                      child: Text(
                        ['💰', '💵', '💎', '💴', '💷'][index % 5],
                        style: TextStyle(
                          fontSize: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    );
                  }),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '당신의 재무 목표를\n실현하세요',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '높은 금리와 다양한 혜택으로\n더 나은 미래를 준비하세요',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF667eea),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '상품 둘러보기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 📊 Stats
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('50+', '다양한 상품'),
                  _buildStatItem('4.5%', '최고 금리'),
                  _buildStatItem('100만+', '가입 고객'),
                ],
              ),
            ),
          ),

          // 📦 카테고리
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '고객님을 위해 준비한',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '딸깍은행만의 특별한 상품들',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  FutureBuilder<List<Product>>(
                    future: _futureProducts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('상품을 불러올 수 없습니다.\n${snapshot.error}'),
                          ),
                        );
                      }

                      final allProducts = snapshot.data ?? [];

                      return Column(
                        children: [
                          _buildCategoryCard(
                            context,
                            '📦',
                            '전체 상품',
                            '모든 예·적금 상품을 한눈에',
                            allProducts.length,
                            Colors.blue,
                                () => _navigateToList(context, '전체 상품', allProducts),
                          ),
                          const SizedBox(height: 16),

                          _buildCategoryCard(
                            context,
                            '💰',
                            '예금',
                            '목돈 굴리기에 최적화된 상품',
                            _filterByCategory(allProducts, '예금').length,
                            Colors.green,
                                () => _navigateToList(
                              context,
                              '예금',
                              _filterByCategory(allProducts, '예금'),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildCategoryCard(
                            context,
                            '💎',
                            '적금',
                            '목돈 만들기를 위한 상품',
                            _filterByCategory(allProducts, '적금').length,
                            Colors.purple,
                                () => _navigateToList(
                              context,
                              '적금',
                              _filterByCategory(allProducts, '적금'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667eea),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
      BuildContext context,
      String emoji,
      String title,
      String subtitle,
      int count,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), Colors.white],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count개 상품',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToList(BuildContext context, String title, List<Product> products) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          title: title,
          products: products,
          baseUrl: widget.baseUrl,
        ),
      ),
    );
  }
}