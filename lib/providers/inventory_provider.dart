import 'package:flutter/material.dart';
import '../services/database_service.dart';

class InventoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get lowStockItems => _lowStockItems;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseService.instance;
      _products = await db.rawQuery('''
        SELECT p.*, c.name as category_name, u.name as unit_name,
               COALESCE(s.quantity, 0) as stock_quantity,
               COALESCE(s.min_stock, 0) as min_stock_level
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN units u ON p.unit_id = u.id
        LEFT JOIN stock s ON p.id = s.product_id
        WHERE p.is_active = 1
        ORDER BY p.name
      ''');

      _lowStockItems = _products.where((p) {
        final q