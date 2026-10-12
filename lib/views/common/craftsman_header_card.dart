import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../services/auth_service.dart';

class CraftsmanHeaderCard extends StatefulWidget {
  final UserModel? currentUser;
  final Function(UserModel) onUserUpdated;
  final VoidCallback onLogout;

  const CraftsmanHeaderCard({
    super.key,
    required this.currentUser,
    required this.onUserUpdated,
    required this.onLogout,
  });

  @override
  State<CraftsmanHeaderCard> createState() => _CraftsmanHeaderCardState();
}

class _CraftsmanHeaderCardState extends State<CraftsmanHeaderCard> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController(text: '28');
  final _passwordController = TextEditingController(text: '1234');
  String _selectedProfession = ServiceCategory.defaultCategories.first.name;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = await _authService.registerCraftsman(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profession: _selectedProfession,
        age: int.tryParse(_ageController.text.trim()) ?? 25,
        password: _passwordController.text.trim(),
      );

      widget.onUserUpdated(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('أهلاً بك يا ${user.name}! تم اعتمادك كـ ($user.profession) ويمكنك الآن التقدم للخدمات.'),
            backgroundColor: Colors.green,
          ),
        );
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
  Widget build(BuildContext context) {
    final user = widget.currentUser;

    // 1. إذا كان المستخدم مسجلاً ولديه حساب فني معتمد
    if (user != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.indigo.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.amber,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'ص',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'معتمد ومفعل',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المهنة: ${user.profession.isNotEmpty ? user.profession : 'فني عام'}  |  العمر: ${user.age} سنة',
                        style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                  tooltip: 'تسجيل خروج',
                  onPressed: widget.onLogout,
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'رصيد المحفظة: ${user.walletBalance.toStringAsFixed(0)} ريال',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'جاهز لاستقبال الطلبات ✓',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. إذا لم يكن مسجلاً -> كارت الانضمام المباشر وطلب الاسم والمهنة والعمر
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.handyman, color: Colors.blue.shade900, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'هل أنت صنايعي أو فني؟',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'سجل بياناتك في ثوانٍ لتبدأ بقبول طلبات الخدمات في منطقتك',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // صف الاسم والعمر
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسمك',
                      hintText: 'مثال: أبو أحمد',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عمرك',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // صف المهنة ورقم الهاتف
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedProfession,
                    decoration: const InputDecoration(
                      labelText: 'مهنتك',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: ServiceCategory.defaultCategories.map((c) {
                      return DropdownMenuItem(value: c.name, child: Text(c.name, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProfession = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم هاتفك',
                      hintText: '05xxxxxxxx',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'تسجيل واعتماد حسابي للتقديم على الخدمات',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
