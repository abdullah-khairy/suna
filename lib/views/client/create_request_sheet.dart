import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../../core/services/location_service.dart';
import '../../services/request_service.dart';

class CreateRequestSheet extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback onRequestCreated;

  const CreateRequestSheet({
    super.key,
    required this.currentUser,
    required this.onRequestCreated,
  });

  @override
  State<CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<CreateRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  String _selectedCategory = ServiceCategory.defaultCategories.first.name;
  GeoPoint? _currentLocation;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.currentUser.location;
    if (_currentLocation == null) {
      _fetchLocation();
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentLocation = loc;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final double budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

      final request = ServiceRequestModel(
        id: '',
        clientId: widget.currentUser.id,
        clientName: widget.currentUser.name,
        clientPhone: widget.currentUser.phone,
        clientLocation: _currentLocation,
        category: _selectedCategory,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        suggestedBudget: budget,
        status: RequestStatus.pendingAdmin,
        createdAt: DateTime.now(),
      );

      await RequestService().createRequest(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلبك بنجاح وهو الآن قيد مراجعة وتسعير الإدارة'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRequestCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
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
                    'طلب خدمة جديدة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // اختيار التصنيف
              const Text('نوع الخدمة المطلوبة:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: ServiceCategory.defaultCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.name,
                    child: Row(
                      children: [
                        Icon(cat.icon, size: 20, color: Colors.blue.shade800),
                        const SizedBox(width: 10),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // عنوان الطلب
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الطلب (مثال: تصليح صنبور مياه)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى كتابة عنوان للخدمة' : null,
              ),
              const SizedBox(height: 16),

              // وصف الخدمة
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'تفاصيل ووصف المشكلة',
                  hintText: 'اشرح ما تريده بدقة ليتم تسعيره بشكل مناسب',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى كتابة وصف الخدمة' : null,
              ),
              const SizedBox(height: 16),

              // الميزانية المقترحة
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'السعر المقترح من طرفك (اختياري)',
                  suffixText: 'ريال / جنيه',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // الموقع الجغرافي
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentLocation != null
                            ? 'تم تحديد الموقع (${_currentLocation!.latitude.toStringAsFixed(2)}, ${_currentLocation!.longitude.toStringAsFixed(2)})'
                            : (_isLoadingLocation ? 'جاري تحديد موقعك...' : 'الموقع غير محدد'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoadingLocation ? null : _fetchLocation,
                      child: const Text('تحديث'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // زر الإرسال
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
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
                        'إرسال الطلب للمراجعة والتسعير',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
