class Product {
  final String id;
  String name;
  double price;
  int quantity; // الكمية المتوفرة في المخزون
  String category;
  String unit; // وحدة القياس: قطعة، كرتون، كيلو...

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.category = 'عام',
    this.unit = 'قطعة',
  });
}
