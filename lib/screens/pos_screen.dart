import 'package:flutter/material.dart';
import '../data/product_store.dart';
import '../models/product.dart';
import 'add_product_screen.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get subtotal => product.price * quantity;
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

  List<Product> get _filteredProducts {
    final all = ProductStore.instance.products;
    if (_search.trim().isEmpty) return all;
    return all.where((p) => p.name.contains(_search.trim())).toList();
  }

  double get _total => _cart.fold(0, (sum, item) => sum + item.subtotal);

  void _addToCart(Product product) {
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكمية غير متوفرة في المخزون')),
      );
      return;
    }
    setState(() {
      final existing = _cart.indexWhere((c) => c.product.id == product.id);
      if (existing != -1) {
        if (_cart[existing].quantity < product.quantity) {
          _cart[existing].quantity++;
        }
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _cart.remove(item);
    });
  }

  void _changeQuantity(CartItem item, int delta) {
    setState(() {
      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _cart.remove(item);
      } else if (newQty <= item.product.quantity) {
        item.quantity = newQty;
      }
    });
  }

  void _checkout() {
    if (_cart.isEmpty) return;

    for (final item in _cart) {
      final newStock = item.product.quantity - item.quantity;
      ProductStore.instance.updateQuantity(item.product.id, newStock);
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تمت العملية بنجاح'),
          content: Text('الإجمالي: ${_total.toStringAsFixed(2)}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _cart.clear());
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نقطة البيع'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              tooltip: 'إضافة منتج',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
                setState(() {});
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'بحث عن منتج...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            Expanded(
              flex: 3,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return Card(
                    child: InkWell(
                      onTap: () => _addToCart(product),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right),
                            const SizedBox(height: 4),
                            Text('${product.price.toStringAsFixed(2)} - متوفر: ${product.quantity}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                          title: Text(item.product.name),
                          subtitle: Text('${item.product.price.toStringAsFixed(2)} × ${item.quantity} = ${item.subtotal.toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _changeQuantity(item, -1),
                              ),
                              Text('${item.quantity}'),
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
                  Text('الإجمالي: ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _cart.isEmpty ? null : _checkout,
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('إتمام البيع'),
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
