import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import 'add_product_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: _buildDrawer(context, user),
      appBar: AppBar(
        title: const Text('Yemen ERP Ultra'),
      ),
floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          if (result == true) {
            inventoryProvider.loadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
        backgroundColor: const Color(0xFF1a237e),
      ),
      body: RefreshIndicator(
        onRefresh: () => inventoryProvider.loadProducts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، ${user?['full_name'] ?? 'مستخدم'} 👋',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a237e),
                ),
              ),
              Text(
                'نظرة عامة على أداء عملك',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              inventoryProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildStatCard(
                          title: 'عدد المنتجات',
                          value: '${inventoryProvider.products.length}',
                          icon: Icons.inventory_2,
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          title: 'منتجات منخفضة المخزون',
                          value: '${inventoryProvider.lowStockItems.length}',
                          icon: Icons.warning_amber,
                          color: const Color(0xFFFF9800),
                        ),
                      ],
                    ),

              const SizedBox(height: 20),
              const Text(
                'قائمة المنتجات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...inventoryProvider.products.map((product) {
                final qty = product['stock_quantity'] ?? 0;
                final minStock = product['min_stock_level'] ?? 0;
                final isLow = (qty as num) <= (minStock as num);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.inventory_2,
                      color: isLow ? Colors.orange : const Color(0xFF1a237e),
                    ),
                    title: Text(product['name'] ?? ''),
                    subtitle: Text('الكمية: $qty'),
                    trailing: Text(
                      '${product['sell_price']} ر.ي',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, Map<String, dynamic>? user) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a237e), Color(0xFF3949ab)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      (user?['full_name'] as String?)?.isNotEmpty == true
                          ? (user!['full_name'] as String)[0]
                          : 'أ',
                      style: const TextStyle(
                        fontSize: 26,
                        color: Color(0xFF1a237e),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?['full_name'] ?? 'مستخدم',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('لوحة التحكم'),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}