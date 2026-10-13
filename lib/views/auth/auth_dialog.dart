import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../services/auth_service.dart';

class AuthDialog extends StatefulWidget {
  final Function(UserModel) onAuthSuccess;

  const AuthDialog({super.key, required this.onAuthSuccess});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLogin = false; // افتراضياً فتح نموذج إنشاء الحساب لتشجيع التسجيل السريع
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '28');
  String _selectedProfession = ServiceCategory.defaultCategories.first.name;

  String _errorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'لا تسمح صلاحيات Firestore بإكمال العملية. تحقق من قواعد قاعدة البيانات.';
        case 'unavailable':
        case 'network-request-failed':
          return 'تعذر الاتصال بالخدمة. تحقق من اتصال الإنترنت ثم أعد المحاولة.';
        default:
          return 'تعذر إكمال العملية بسبب خطأ في قاعدة البيانات (${error.code}).';
      }
    }

    return 'تعذر إكمال العملية. يرجى المحاولة مرة أخرى.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final user = await _authService.loginWithPhone(phone: _phoneController.text.trim(), password: _passwordController.text.trim());

        if (user != null) {
          if (mounted) {
            Navigator.pop(context);
            widget.onAuthSuccess(user);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف أو كلمة المرور غير صحيحة'), backgroundColor: Colors.red));
          }
        }
      } else {
        final user = await _authService.registerCraftsman(name: _nameController.text.trim(), phone: _phoneController.text.trim(), profession: _selectedProfession, age: int.tryParse(_ageController.text.trim()) ?? 25, password: _passwordController.text.trim());

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أهلاً بك يا ${user.name}! تم اعتماد حسابك كمهني بنجاح.'), backgroundColor: Colors.green));
          widget.onAuthSuccess(user);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(e)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isLogin ? 'تسجيل الدخول' : 'انضم الي نقابه المغامرين', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال اسمك' : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedProfession,
                    decoration: const InputDecoration(labelText: 'مهنتك / تخصصك', prefixIcon: Icon(Icons.handyman), border: OutlineInputBorder()),
                    items: ServiceCategory.defaultCategories.map((c) {
                      return DropdownMenuItem(value: c.name, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProfession = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'العمر (بالسنوات)', prefixIcon: Icon(Icons.cake), border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'يرجى كتابة عمرك' : null,
                  ),
                  const SizedBox(height: 12),
                ],

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف', hintText: '05xxxxxxxx', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                  validator: (v) => v == null || v.length < 4 ? 'كلمة المرور يجب أن لا تقل عن 4 خانات' : null,
                ),
                const SizedBox(height: 18),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isLogin ? 'دخول' : 'تسجيل وبدء استقبال الطلبات', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'انشئ حساب جديد' : 'لديك حساب بالفعل؟ تسجيل الدخول')),
                // const Divider(),
                // TextButton.icon(
                //   onPressed: () {
                //     setState(() {
                //       _isLogin = true;
                //       _phoneController.text = '0500000000';
                //       _passwordController.text = 'admin';
                //     });
                //   },
                //   icon: const Icon(Icons.shield, color: Colors.amber, size: 18),
                //   label: const Text(
                //     'تجربة الدخول بحساب الإدارة (0500000000)',
                //     style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
