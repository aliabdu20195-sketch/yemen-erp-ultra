import 'package:flutter/material.dart';
import '../data/product_store.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController(text: 'قطعة');

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final newProduct = Product(
      id: ProductStore.instance.generateId(),
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text),
      quantity: int.parse(_quantityController.text),
      category: _categoryController.text.trim().isEmpty
          ? 'عام'
          : _categoryController.text.trim(),
      unit: _unitController.text.trim().isEmpty
          ? 'قطعة'
          : _unitController.text.trim(),
    );

    ProductStore.instance.addProduct(newProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة المنتج بنجاح')),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة منتج جديد')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'الرجاء إدخال اسم المنتج' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'الرجاء إدخال السعر';
                    if (double.tryParse(value) == null) return 'قيمة غير صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية المتوفرة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'الرجاء إدخال الكمية';
                    if (int.tryParse(value) == null) return 'قيمة غير صحيحة';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'وحدة القياس',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saveProduct,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ المنتج'),
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
