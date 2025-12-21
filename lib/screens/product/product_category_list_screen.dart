import 'package:flutter/material.dart';
import 'package:tkbank/models/product.dart';
import 'package:tkbank/services/product_service.dart';
import 'product_detail_screen.dart';
import '../product/interest_calculator_screen.dart';  // ✅ 금리계산기!

/// 카테고리별 상품 리스트 화면
class ProductCategoryListScreen extends StatefulWidget {
  final String baseUrl;
  final String categoryName;
  final String categoryCode;

  const ProductCategoryListScreen({
    super.key,
    required this.baseUrl,
    required this.categoryName,
    required this.categoryCode,
  });

  @override
  State<ProductCategoryListScreen> createState() =>
      _ProductCategoryListScreenState();
}

class _ProductCategoryListScreenState
    extends State<ProductCategoryListScreen> {
  late ProductService _service;
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ProductService(widget.baseUrl);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products =
      await _service.fetchProductsByCategory(widget.categoryCode);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ✅✅✅ 금리계산기 버튼 추가! ✅✅✅
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InterestCalculatorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.calculate, size: 24),
              label: const Text(
                '금리 계산기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),

          // ✅ 상품 리스트
          Expanded(
            child: _products.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.categoryName} 상품이 없습니다',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _buildProductCard(product);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 배지
              Row(
                children: [
                  if (product.joinTypes?.contains('MOBILE') == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '모바일',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '신상품',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // 설명
              Text(
                product.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // 금리 정보 (있을 경우만)
              if (product.maturityRate > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${_formatNumber(product.maturityRate)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          '(기본 연 ${_formatNumber(product.baseRate)}%, 12개월 세전)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
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
    );
  }

  Widget _buildJoinTypeChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}