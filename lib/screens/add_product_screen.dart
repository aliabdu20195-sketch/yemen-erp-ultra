import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _units = [];
  int? _selectedCategoryId;
  int? _selectedUnitId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final categories = await DatabaseService.instance.getAll('categories');
    final units = await DatabaseService.instance.getAll('units');
    setState(() {
      _categories = categories;
      _units = units;
      _selectedCategoryId = categories.isNotEmpty ? categories.first['id'] as int : null;
      _selectedUnitId = units.isNotEmpty ? units.first['id'] as int : null;
      _isLoading = false;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة تصنيف ووحدة أولاً')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final productId = await DatabaseService.instance.insert('products', {
        'code': _codeController.text.trim(),
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
        'unit_id': _selectedUnitId,
        'buy_price': double.tryParse(_buyPriceController.text) ?? 0.0,
        'sell_price': double.tryParse(_sellPriceController.text) ?? 0.0,
        'wholesale_price': double.tryParse(_wholesalePriceController.text) ?? 0.0,
      });

      await DatabaseService.instance.insert('stock', {
        'product_id': productId,
        'warehouse_id': 1,
        'quantity': double.tryParse(_quantityController.text) ?? 0.0,
        'min_stock': 5,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المنتج بنجاح')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: يمكن كود المنتج مكرر')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'كود المنتج', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
                      items: _categories
                          .map((c) => DropdownMenuItem<int>(
                                value: c['id'] as int,
                                child: Text(c['name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedUnitId,
                      decoration: const InputDecoration(labelText: 'الوحدة', border: OutlineInputBorder()),
                      items: _units
                          .map((u) => DropdownMenuItem<int>(
                                value: u['id'] as int,
                                child: Text(u['name'] as String),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUnitId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _buyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر الشراء', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sellPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر البيع', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _wholesalePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر الجملة', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الكمية الأولية بالمخزون', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('حفظ المنتج'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
