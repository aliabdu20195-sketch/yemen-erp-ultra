import '../models/product.dart';

/// مخزن بسيط في الذاكرة (Singleton) لحفظ قائمة المنتجات
/// مؤقتاً بدون قاعدة بيانات - لاحقاً يمكن ربطه بـ SQLite أو API
class ProductStore {
  ProductStore._internal();
  static final ProductStore instance = ProductStore._internal();

  final List<Product> products = [
    Product(id: 'p1', name: 'أرز بسمتي 5 كيلو', price: 12.5, quantity: 40, category: 'مواد غذائية', unit: 'كيس'),
    Product(id: 'p2', name: 'سكر أبيض 1 كيلو', price: 1.2, quantity: 100, category: 'مواد غذائية', unit: 'كيس'),
    Product(id: 'p3', name: 'زيت طبخ 1.5 لتر', price: 3.8, quantity: 60, category: 'مواد غذائية', unit: 'عبوة'),
    Product(id: 'p4', name: 'شاي أحمر 100 كيس', price: 2.5, quantity: 75, category: 'مواد غذائية', unit: 'علبة'),
    Product(id: 'p5', name: 'صابون غسيل', price: 0.9, quantity: 120, category: 'مستلزمات منزلية', unit: 'قطعة'),
  ];

  void addProduct(Product product) {
    products.add(product);
  }

  void updateQuantity(String id, int newQuantity) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      products[index].quantity = newQuantity;
    }
  }

  String generateId() => 'p${DateTime.now().millisecondsSinceEpoch}';
}
