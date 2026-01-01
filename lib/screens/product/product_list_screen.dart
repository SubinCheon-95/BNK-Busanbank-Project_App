import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({
    super.key,
    required this.title,
    required this.products,
    this.baseUrl,
  });

  final String title;
  final List<Product> products;
  final String? baseUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Container( // 👈 Container로 감싸기!
        color: Colors.white,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (ctx, idx) {
            final product = products[idx];
            return ProductCard(
              product: product,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(
                          baseUrl: baseUrl ?? '',
                          product: product,
                        ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}