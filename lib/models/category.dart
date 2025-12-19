class Category {
  final int categoryId;
  final String categoryName;
  final String? routePath;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.routePath,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      routePath: json['routePath'],
    );
  }
}