import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/category_tabs.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductMainScreen extends StatefulWidget {
  const ProductMainScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<ProductMainScreen> createState() => _ProductMainScreenState();
}

class _ProductMainScreenState extends State<ProductMainScreen> {
  late ProductService _service;
  late Future<List<Product>> _futureProducts;

  String selectedCategory = '전체';

  @override
  void initState() {
    super.initState();
    _service = ProductService(widget.baseUrl);
    _futureProducts = _service.fetchProducts();

    requestPermission();  //firebase - 작성자: 윤종인
  }

  // 🔹 알림 권한 요청
  Future<void> requestPermission() async {  //firebase - 작성자: 윤종인
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('알림 권한 상태: ${settings.authorizationStatus}');

    final token = await messaging.getToken();
    print('FCM Token: $token');
  }

  List<Product> _filterByCategory(List<Product> all) {
    if (selectedCategory == '전체') return all;

    return all.where((p) {
      // productType: "01" 예금, "02" 적금 (백엔드 JSON 기준)
      if (selectedCategory == '예금') {
        return p.type == '01';
      } else if (selectedCategory == '적금') {
        return p.type == '02';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['전체', '예금', '적금'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('딸깍은행 상품몰'),
      ),
      body: Column(
        children: [
          CategoryTabs(
            categories: categories,
            selected: selectedCategory,
            onChanged: (c) => setState(() => selectedCategory = c),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('상품을 불러오지 못했습니다.\n${snapshot.error}'),
                  );
                }

                final products = snapshot.data ?? [];
                final filtered = _filterByCategory(products);

                if (filtered.isEmpty) {
                  return const Center(child: Text('해당 조건에 맞는 상품이 없습니다.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final product = filtered[idx];
                    return ProductCard(
                      product: product,
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}