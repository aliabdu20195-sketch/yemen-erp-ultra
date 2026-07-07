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
        final qty = (p['stock_quantity'] as num?) ?? 0;
        final min = (p['min_stock_level'] as num?) ?? 0;
        return qty <= min;
      }).toList();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseService.instance;
      _products = await db.rawQuery('''
        SELECT p.*, c.name as category_name, u.name as unit_name,
               COALESCE(s.quantity, 0) as stock_quantity
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN units u ON p.unit_id = u.id
        LEFT JOIN stock s ON p.id = s.product_id
        WHERE p.is_active = 1 
        AND (p.name LIKE ? OR p.code LIKE ? OR p.barcode LIKE ?)
        ORDER BY p.name
      ''', ['%$query%', '%$query%', '%$query%']);
    } catch (e) {
      debugPrint('Error searching products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    required String movementType,
    String? notes,
  }) async {
    try {
      final db = DatabaseService.instance;
      final delta = (movementType == 'out') ? -quantity : quantity;

      final existing = await db.rawQuery(
        'SELECT * FROM stock WHERE product_id = ? AND warehouse_id = ?',
        [productId, warehouseId],
      );

      if (existing.isEmpty) {
        if (delta < 0) {
          debugPrint('Cannot remove stock: no existing record');
          return false;
        }
        await db.insert('stock', {
          'product_id': productId,
          'warehouse_id': warehouseId,
          'quantity': delta,
          'min_stock': 0,
          'max_stock': 0,
        });
      } else {
        final currentQty = (existing.first['quantity'] as num).toDouble();
        final newQty = currentQty + delta;

        if (newQty < 0) {
          debugPrint('Cannot reduce stock below zero');
          return false;
        }

        await db.update('stock', {
          'quantity': newQty,
        }, existing.first['id'] as int);
      }

      await db.insert('stock_movements', {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'movement_type': movementType,
        'quantity': quantity,
        'notes': notes,
      });

      await loadProducts();
      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }
}
