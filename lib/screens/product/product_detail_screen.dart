import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';
import '../../models/product_join_request.dart';
import '../member/login_screen.dart';
import 'join/join_step1_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.baseUrl,
    required this.product,
  });

  final String baseUrl;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const defaultTerm = 12;
    final endDate = DateTime(today.year, today.month + defaultTerm, today.day);

    final joinReq = ProductJoinRequest(
      productNo: product.productNo,
      productName: product.name,
      productType: product.type,
      principalAmount: 1_000_000,
      contractTerm: defaultTerm,
      startDate: today,
      expectedEndDate: endDate,
      baseRate: product.baseRate,
      applyRate: product.baseRate,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품명
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 설명
              Text(
                product.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),

              // 금리 정보
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        '기본 금리',
                        '연 ${product.baseRate.toStringAsFixed(2)}%',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        '최고 금리',
                        '연 ${product.maturityRate.toStringAsFixed(2)}%',
                        Icons.star,
                        Colors.orange,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        '상품 유형',
                        product.type == "01" ? "예금" : "적금",
                        Icons.account_balance,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // 하단 고정 버튼
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _handleJoin(context, joinReq),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '가입 신청하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ 로그인 체크 후 가입 진행!
  void _handleJoin(BuildContext context, ProductJoinRequest joinReq) {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      // 로그인 안 되어 있으면 로그인 화면으로
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('로그인 필요'),
          content: const Text('상품 가입을 위해 로그인이 필요합니다.\n로그인 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                ).then((_) {
                  // 로그인 후 돌아왔을 때 다시 체크
                  if (authProvider.isLoggedIn) {
                    _navigateToJoin(context, joinReq);
                  }
                });
              },
              child: const Text('로그인'),
            ),
          ],
        ),
      );
    } else {
      // 로그인 되어 있으면 바로 가입 화면으로
      _navigateToJoin(context, joinReq);
    }
  }

  void _navigateToJoin(BuildContext context, ProductJoinRequest joinReq) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinStep1Screen(
          baseUrl: baseUrl,
          request: joinReq,
        ),
      ),
    );
  }
}