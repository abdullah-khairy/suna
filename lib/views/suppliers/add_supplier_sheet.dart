import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/supplier_model.dart';
import '../../core/services/location_service.dart';
import '../../services/supplier_service.dart';

class AddSupplierSheet extends StatefulWidget {
  final VoidCallback onSupplierAdded;

  const AddSupplierSheet({super.key, required this.onSupplierAdded});

  @override
  State<AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<AddSupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  final SupplierService _supplierService = SupplierService();

  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = SupplierModel.categories.first;
  bool _deliveryAvailable = true;
  GeoPoint? _shopLocation;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _shopLocation = loc;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final supplier = SupplierModel(
        id: '',
        name: _nameController.text.trim(),
        ownerName: _ownerController.text.trim(),
        phone: _phoneController.text.trim(),
        category: _selectedCategory,
        description: _descController.text.trim(),
        addressTitle: _addressController.text.trim(),
        location: _shopLocation,
        deliveryAvailable: _deliveryAvailable,
        createdAt: DateTime.now(),
      );

      await _supplierService.addSupplier(supplier);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة محلك بنجاح! سيظهر الآن للفنيين والعملاء في المنطقة.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSupplierAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إضافة محل أو مورد مون',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // اسم المحل
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المحل / المورد (مثال: البركة للحدايد والبويات)',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'يرجى كتابة اسم المحل' : null,
              ),
              const SizedBox(height: 12),

              // اسم المسؤول ورقم الهاتف
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ownerController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المسؤول',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف للطلبات',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // قسم ونوع المونة
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'قسم ونوع المونة',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: SupplierModel.categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),

              // العنوان المكتوب
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان / المنطقة بالتفصيل',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'يرجى كتابة العنوان' : null,
              ),
              const SizedBox(height: 12),

              // وصف المنتجات والمون المتوفرة
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'المنتجات والمون المتوفرة',
                  hintText: 'مثال: أسمنت ممتاز، رمل ناعم وخشن، دهانات جوتن، مواسير ومحابس...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'يرجى توضيح المنتجات' : null,
              ),
              const SizedBox(height: 12),

              // توفر التوصيل
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('هل يتوفر توصيل ونقل للموقع؟', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('سيظهر للصنايعي والعميل أنك توفر شحن ونقل للموقع', style: TextStyle(fontSize: 11)),
                value: _deliveryAvailable,
                activeThumbColor: Colors.blue.shade900,
                onChanged: (val) => setState(() => _deliveryAvailable = val),
              ),
              const SizedBox(height: 8),

              // الموقع الجغرافي
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _shopLocation != null
                            ? 'تم تحديد موقع المحل على الخريطة ✓'
                            : (_isLoadingLocation ? 'جاري تحديد إحداثيات المحل...' : 'لم يتم تحديد الإحداثيات'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoadingLocation ? null : _fetchLocation,
                      child: const Text('تحديث'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'إضافة المحل إلى دليل الموردين',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
