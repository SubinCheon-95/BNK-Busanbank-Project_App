// 2025/12/18 - 나의 금융상품 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_product_service.dart';
import '../../models/user_product.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final UserProductService _productService = UserProductService();

  List<UserProduct> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('로그인 필요');
      }

      final products = await _productService.getUserProducts(userId);

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품 조회 실패: $e')),
        );
      }
    }
  }

  Future<void> _terminateProduct(UserProduct product) async {
    print('[DEBUG] 해지 버튼 클릭됨 - 상품명: ${product.productName}');

    // Get userId before async operation to avoid BuildContext across async gaps
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    print('[DEBUG] userId: $userId');

    if (userId == null) {
      print('[ERROR] userId가 null입니다');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
      }
      return;
    }

    print('[DEBUG] 해지 확인 다이얼로그 표시');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상품 해지'),
        content: Text('${product.productName}을(를) 해지하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              print('[DEBUG] 취소 버튼 클릭');
              Navigator.pop(context, false);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              print('[DEBUG] 해지 버튼 클릭');
              Navigator.pop(context, true);
            },
            child: const Text('해지'),
          ),
        ],
      ),
    );

    print('[DEBUG] 다이얼로그 결과: $confirmed');
    if (confirmed != true) return;

    try {
      print('[DEBUG] 해지 요청 시작 - userId: $userId, productNo: ${product.productNo}, startDate: ${product.startDate}');

      await _productService.terminateProduct(
        userId: userId,
        productNo: product.productNo,
        startDate: product.startDate,
      );

      print('[DEBUG] 해지 성공');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품이 해지되었습니다')),
        );
        _loadProducts(); // 목록 새로고침
      }
    } catch (e) {
      print('[ERROR] 해지 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상품 해지 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 금융상품'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('가입한 상품이 없습니다'))
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return _buildProductCard(product, formatter);
                    },
                  ),
                ),
    );
  }

  Widget _buildProductCard(UserProduct product, NumberFormat formatter) {
    print('[DEBUG] 상품 카드 빌드 - 상품명: ${product.productName}, isActive: ${product.isActive}');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.isActive ? '활성' : '해지',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('원금', '${formatter.format(product.principalAmount)}원'),
            _buildInfoRow('금리', '${product.applyRate}%'),
            _buildInfoRow('가입일', product.startDate),
            if (product.expectedEndDate != null)
              _buildInfoRow('만기일', product.expectedEndDate!),
            if (product.contractTerm != null)
              _buildInfoRow('계약기간', '${product.contractTerm}개월'),
            if (product.accountNo != null)
              _buildInfoRow('계좌번호', product.accountNo!),
            // 해지 버튼 영역
            Builder(
              builder: (context) {
                if (product.isActive) {
                  print('[DEBUG] 해지 버튼 렌더링 - 상품명: ${product.productName}');
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          print('[DEBUG] GestureDetector 터치됨!');
                          _terminateProduct(product);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '상품 해지',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  print('[DEBUG] 해지 버튼 미표시 - 상품명: ${product.productName}, isActive: false');
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
