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
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '0');

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
    final db = DatabaseService.instance;
    final categories = await db.getAll('categories', orderBy: 'name');
    final units = await db.getAll('units', orderBy: 'name');

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
        const SnackBar(content: Text('الرجاء إضافة تصنيف ووحدة قياس أولاً')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final db = DatabaseService.instance;

    try {
      final productId = await db.insert('products', {
        'code': _codeController.text.trim(),
        'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
        'unit_id': _selectedUnitId,
        'buy_price': double.parse(_buyPriceController.text),
        'sell_price': double.parse(_sellPriceController.text),
        'wholesale_price': _wholesalePriceController.text.trim().isEmpty
            ? 0.0
            : double.parse(_wholesalePriceController.text),
      });

      // إضافة رصيد مبدئي في المخزن الرئيسي (warehouse_id = 1)
      await db.insert('stock', {
        'product_id': productId,
        'warehouse_id': 1,
        'quantity': double.parse(_quantityController.text),
        'min_stock': double.parse(_minStockController.text),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المنتج بنجاح')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('UNIQUE')
          ? 'رمز المنتج (Code) مستخدم مسبقاً، اختر رمزاً آخر'
          : 'حدث خطأ أثناء الحفظ';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _wholesalePriceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? 'حقل مطلوب' : null;

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'حقل مطلوب';
    if (double.tryParse(value) == null) return 'قيمة غير صحيحة';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة منتج جديد')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'رمز المنتج (Code)',
                          border: OutlineInputBorder(),
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'الباركود (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج',
                          border: OutlineInputBorder(),
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'التصنيف',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem<int>(
                                  value: c['id'] as int,
                                  child: Text(c['name'] as String),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCategoryId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>( 
                      value: _selectedUnitId,
                        decoration: const InputDecoration(
                          labelText: 'وحدة القياس',
                          border: OutlineInputBorder(),
                        ),
                        items: _units
                            .map((u) => DropdownMenuItem<int>(
                                  value: u['id'] as int,
                                  child: Text(u['name'] as String),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedUnitId = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _buyPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'سعر الشراء',
                          border: OutlineInputBorder(),
                        ),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sellPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'سعر البيع',
                          border: OutlineInputBorder(),
                        ),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _wholesalePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'سعر الجملة (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const Divider(height: 32),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'الكمية المبدئية بالمخزن',
                          border: OutlineInputBorder(),
                        ),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _minStockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'الحد الأدنى للتنبيه',
                          border: OutlineInputBorder(),
                        ),
                        validator: _numberValidator,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProduct,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ المنتج'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
