import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/category_model.dart';
import '../../core/utils/currency_helper.dart';
import '../../services/auth_service.dart';

class CraftsmanHeaderCard extends StatefulWidget {
  final UserModel? currentUser;
  final Function(UserModel) onUserUpdated;
  final VoidCallback onLogout;

  const CraftsmanHeaderCard({super.key, required this.currentUser, required this.onUserUpdated, required this.onLogout});

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
      final user = await _authService.registerCraftsman(name: _nameController.text.trim(), phone: _phoneController.text.trim(), profession: _selectedProfession, age: int.tryParse(_ageController.text.trim()) ?? 25, password: _passwordController.text.trim());

      widget.onUserUpdated(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أهلاً بك يا ${user.name}! تم اعتمادك كـ ($user.profession) ويمكنك الآن التقدم للخدمات.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
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
          gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.indigo.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: Colors.blue.shade900.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
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
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
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
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                            child: const Text(
                              'معتمد ومفعل',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('المهنة: ${user.profession.isNotEmpty ? user.profession : 'فني عام'}  |  العمر: ${user.age} سنة', style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
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
            const SizedBox(height: 12),

            // شريط إحصائيات المغامر: عدد النجوم + عدد الخدمات المنجزة + رصيد المحفظة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  // 1. عدد النجوم والتقييم
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 19),
                            const SizedBox(width: 4),
                            Text(
                              user.rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final filled = (i + 1) <= user.rating.round();
                            return Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 14);
                          }),
                        ),
                        const SizedBox(height: 2),
                        Text('${user.ratingsCount} تقييم', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
                      ],
                    ),
                  ),

                  Container(width: 1, height: 42, color: Colors.white24),

                  // 2. عدد الخدمات التي قام بها
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_outlined, color: Colors.greenAccent, size: 19),
                        const SizedBox(height: 2),
                        Text(
                          '${user.completedTasksCount} خدمة',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text('أنجزت بنجاح', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
                      ],
                    ),
                  ),

                  Container(width: 1, height: 42, color: Colors.white24),

                  // 3. رصيد المحفظة
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.amber, size: 19),
                        const SizedBox(height: 2),
                        Text(
                          '${user.walletBalance.toStringAsFixed(0)} ${CurrencyHelper.resolveCurrency(location: user.location, phone: user.phone)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text('المحفظة', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text('جاهز لاستقبال طلبات منطقتك', style: TextStyle(color: Colors.blue.shade100, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    'حساب مهني موثق ✓',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. إذا لم يكن مسجلاً -> كارت الانضمام المباشر وطلب الاسم والمهنة والعمر
    if (user != null && user.role == UserRole.provider && user.isApproved == false) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blue.shade200, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.blue.shade100.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))],
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
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.handyman, color: Colors.blue.shade900, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('انضم الي نقابه المغامرين وابدأ بتقديم خدماتك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('سجل بياناتك في ثوانٍ لتبدأ بقبول طلبات الخدمات في منطقتك', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                      decoration: const InputDecoration(labelText: 'اسمك', hintText: 'مثال: أبو أحمد', isDense: true, border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'عمرك', isDense: true, border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'مهنتك', isDense: true, border: OutlineInputBorder()),
                      items: ServiceCategory.defaultCategories.map((c) {
                        return DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name, style: const TextStyle(fontSize: 13)),
                        );
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
                      decoration: const InputDecoration(labelText: 'رقم هاتفك', hintText: '05xxxxxxxx', isDense: true, border: OutlineInputBorder()),
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
                child: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('تسجيل واعتماد حسابي للتقديم على الخدمات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
