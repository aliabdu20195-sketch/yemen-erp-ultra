import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/database_service.dart';

class CartItem {
  final Map<String, dynamic> product;
  double quantity;
  CartItem({required this.product, this.quantity = 1});

  double get unitPrice => (product['sell_price'] as num).toDouble();
  double get subtotal => unitPrice * quantity;
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<CartItem> _cart = [];
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  bool _isCheckingOut = false;

  double get _total => _cart.fold(0, (sum, item) => sum + item.subtotal);

  List<Map<String, dynamic>> _filterProducts(List<Map<String, dynamic>> products) {
    if (_search.trim().isEmpty) return products;
    final query = _search.trim();
    return products.where((p) {
      final name = (p['name'] as String?) ?? '';
      final code = (p['code'] as String?) ?? '';
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  double _availableStock(Map<String, dynamic> product) =>
      ((product['stock_quantity'] as num?) ?? 0).toDouble();

  void _addToCart(Map<String, dynamic> product) {
    final available = _availableStock(product);
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكمية غير متوفرة في المخزون')),
      );
      return;
    }
    setState(() {
      final existingIndex = _cart.indexWhere((c) => c.product['id'] == product['id']);
      if (existingIndex != -1) {
        if (_cart[existingIndex].quantity < available) {
          _cart[existingIndex].quantity += 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد كمية إضافية متوفرة')),
          );
        }
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _changeQuantity(CartItem item, double delta) {
    setState(() {
      final newQty = item.quantity + delta;
      final available = _availableStock(item.product);
      if (newQty <= 0) {
        _cart.remove(item);
      } else if (newQty <= available) {
        item.quantity = newQty;
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() => _cart.remove(item));
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty || _isCheckingOut) return;
    setState(() => _isCheckingOut = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final db = DatabaseService.instance;
    final userId = authProvider.currentUser?['id'] as int?;

    try {
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      final invoiceId = await db.insert('sales_invoices', {
        'invoice_number': invoiceNumber,
        'customer_id': null,
        'user_id': userId,
        'subtotal': _total,
        'discount_amount': 0.0,
        'tax_amount': 0.0,
        'total': _total,
        'paid': _total,
        'due': 0.0,
        'invoice_date': DateTime.now().toIso8601String(),
        'status': 'completed',
      });

      for (final item in _cart) {
        await db.insert('sales_invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item.product['id'],
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.subtotal,
        });

        await inventoryProvider.updateStock(
          productId: item.product['id'] as int,
          warehouseId: 1,
          quantity: item.quantity,
          movementType: 'out',
          notes: 'بيع - فاتورة $invoiceNumber',
        );
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تمت العملية بنجاح'),
            content: Text('رقم الفاتورة: $invoiceNumber\nالإجمالي: ${_total.toStringAsFixed(2)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        ),
      );
      setState(() => _cart.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء إتمام عملية البيع')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final products = _filterProducts(inventoryProvider.products);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('نقطة البيع')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'بحث بالاسم أو الرمز...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            Expanded(
              flex: 3,
              child: inventoryProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final stock = _availableStock(product);
                        final outOfStock = stock <= 0;
                        return Card(
                          color: outOfStock ? Colors.grey[200] : null,
                          child: InkWell(
                            onTap: outOfStock ? null : () => _addToCart(product),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    product['name'] as String? ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(product['sell_price'] as num).toStringAsFixed(2)} - متوفر: ${stock.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: outOfStock ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 2,
              child: _cart.isEmpty
                  ? const Center(child: Text('السلة فارغة - اضغط على منتج للإضافة'))
                  : ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return ListTile(
                          title: Text(item.product['name'] as String? ?? ''),
                          subtitle: Text(
                            '${item.unitPrice.toStringAsFixed(2)} × ${item.quantity.toStringAsFixed(0)} = ${item.subtotal.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _changeQuantity(item, -1),
                              ),
                              Text(item.quantity.toStringAsFixed(0)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _changeQuantity(item, 1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeFromCart(item),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإجمالي: ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: (_cart.isEmpty || _isCheckingOut) ? null : _checkout,
                    icon: _isCheckingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.point_of_sale),
                    label: Text(_isCheckingOut ? 'جاري الحفظ...' : 'إتمام البيع'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
