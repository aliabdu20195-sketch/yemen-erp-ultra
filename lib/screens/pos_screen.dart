import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/database_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // productId -> {product: Map, quantity: int}
  final Map<int, Map<String, dynamic>> _cart = {};
  bool _isSaving = false;

  double get _total {
    double sum = 0;
    _cart.forEach((id, item) {
      final price = (item['product']['sell_price'] as num).toDouble();
      final qty = item['quantity'] as int;
      sum += price * qty;
    });
    return sum;
  }

  void _addToCart(Map<String, dynamic> product) {
    final id = product['id'] as int;
    final availableQty = (product['stock_quantity'] ?? 0) as num;

    setState(() {
      if (_cart.containsKey(id)) {
        final currentQty = _cart[id]!['quantity'] as int;
        if (currentQty + 1 > availableQty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الكمية المتوفرة بالمخزون غير كافية')),
          );
          return;
        }
        _cart[id]!['quantity'] = currentQty + 1;
      } else {
        if (availableQty < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('المنتج غير متوفر بالمخزون')),
          );
          return;
        }
        _cart[id] = {'product': product, 'quantity': 1};
      }
    });
  }

  void _decreaseQty(int productId) {
    setState(() {
      final currentQty = _cart[productId]!['quantity'] as int;
      if (currentQty <= 1) {
        _cart.remove(productId);
      } else {
        _cart[productId]!['quantity'] = currentQty - 1;
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'] as int?;

      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().toIso8601String();
      final total = _total;

      final invoiceId = await DatabaseService.instance.insert('sales_invoices', {
        'invoice_number': invoiceNumber,
        'user_id': userId,
        'subtotal': total,
        'discount_amount': 0,
        'tax_amount': 0,
        'total': total,
        'paid': total,
        'due': 0,
        'invoice_date': now,
        'status': 'completed',
      });

      for (final entry in _cart.entries) {
        final product = entry.value['product'] as Map<String, dynamic>;
        final qty = entry.value['quantity'] as int;
        final price = (product['sell_price'] as num).toDouble();

        await DatabaseService.instance.insert('sales_invoice_items', {
          'invoice_id': invoiceId,
          'product_id': product['id'],
          'quantity': qty,
          'unit_price': price,
          'total': price * qty,
        });

        await DatabaseService.instance.rawExecute(
          'UPDATE stock SET quantity = quantity - ? WHERE product_id = ? AND warehouse_id = 1',
          [qty, product['id']],
        );

        await DatabaseService.instance.insert('stock_movements', {
          'product_id': product['id'],
          'warehouse_id': 1,
          'movement_type': 'sale',
          'quantity': -qty,
          'notes': 'فاتورة $invoiceNumber',
        });
      }

      await inventoryProvider.loadProducts();

      if (mounted) {
        setState(() => _cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ الفاتورة $invoiceNumber بنجاح')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حفظ الفاتورة')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final products = inventoryProvider.products;

    return Scaffold(
      appBar: AppBar(title: const Text('نقطة البيع')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final qty = (product['stock_quantity'] ?? 0) as num;
                final inCart = _cart[product['id']]?['quantity'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(product['name'] ?? ''),
                    subtitle: Text('متوفر: $qty | ${product['sell_price']} ر.ي'),
                    trailing: inCart > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _decreaseQty(product['id'] as int),
                              ),
                              Text('$inCart', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _addToCart(product),
                              ),
                            ],
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () => _addToCart(product),
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'الإجمالي: ${_total.toStringAsFixed(0)} ر.ي',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (_cart.isEmpty || _isSaving) ? null : _checkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a237e),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('إتمام البيع', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
