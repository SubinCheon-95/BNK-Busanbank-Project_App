// lib/screen/product/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:kmarket_shopping_app/model/product.dart';
import 'package:kmarket_shopping_app/model/product_join_request.dart';
import 'package:kmarket_shopping_app/screen/product/join/join_step1_screen.dart';

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

    // ✅ STEP1으로 넘길 초기 가입 요청 정보
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
      // 나머지 필드는 기본값 사용
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(product.description),
            const SizedBox(height: 16),
            Text('기본 금리: 연 ${product.baseRate.toStringAsFixed(2)}%'),
            const SizedBox(height: 8),
            Text('상품 유형: ${product.type == "01" ? "예금" : "적금"}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JoinStep1Screen(
                        baseUrl: baseUrl,
                        request: joinReq,
                      ),
                    ),
                  );
                },
                child: const Text('가입 신청하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}