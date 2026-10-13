import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../../models/supplier_model.dart';
import '../../services/request_service.dart';
import '../../services/supplier_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel adminUser;

  const AdminDashboardScreen({super.key, required this.adminUser});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RequestService _requestService = RequestService();
  final SupplierService _supplierService = SupplierService();
  bool _isSeedingSuppliers = false;
  bool _isSeedingRequests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.amber),
            SizedBox(width: 8),
            Text('لوحة تحكم الإدارة', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: _isSeedingRequests
          //       ? const SizedBox(
          //           width: 18,
          //           height: 18,
          //           child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          //         )
          //       : const Icon(Icons.cloud_sync),
          //   tooltip: 'مزامنة طلبات الخدمات الحقيقية',
          //   onPressed: _isSeedingRequests
          //       ? null
          //       : () async {
          //           setState(() => _isSeedingRequests = true);
          //           final messenger = ScaffoldMessenger.of(context);
          //           final count = await _requestService.seedBulkRealServiceRequests(force: true);
          //           if (mounted) {
          //             setState(() => _isSeedingRequests = false);
          //             messenger.showSnackBar(
          //               SnackBar(
          //                 content: Text('تمت مزامنة ونشر $count طلب خدمة حقيقي في فايربيز! 🎉'),
          //                 backgroundColor: Colors.green,
          //               ),
          //             );
          //           }
          //         },
          // ),
        ],
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.rate_review), text: 'طلبات تحتاج تسعير'),
            Tab(icon: Icon(Icons.people), text: 'الفنيين'),
            Tab(icon: Icon(Icons.storefront), text: 'الموردين (1000+)'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildPendingRequestsTab(), _buildCraftsmenManagementTab(), _buildSuppliersManagementTab()]),
    );
  }

  // 1. تبويب مراجعة وتسعير طلبات العملاء
  Widget _buildPendingRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('service_requests').where('status', isEqualTo: RequestStatus.pendingAdmin.name).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  const Text('رائع! لا توجد طلبات معلقة حالياً.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('جميع طلبات العملاء تم تسعيرها واعتمادها.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 24),
                  // ElevatedButton.icon(
                  //   onPressed: _isSeedingRequests
                  //       ? null
                  //       : () async {
                  //           setState(() => _isSeedingRequests = true);
                  //           final messenger = ScaffoldMessenger.of(context);
                  //           final count = await _requestService.seedBulkRealServiceRequests(force: true);
                  //           if (mounted) {
                  //             setState(() => _isSeedingRequests = false);
                  //             messenger.showSnackBar(SnackBar(content: Text('تمت مزامنة ونشر $count طلب خدمة حقيقي في فايربيز! 🎉'), backgroundColor: Colors.green));
                  //           }
                  //         },
                  //   icon: _isSeedingRequests ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.post_add),
                  //   label: Text(_isSeedingRequests ? 'جاري الاستيراد والنشر...' : 'مزامنة وزرع طلبات السوق الحقيقية الآن (60+ طلب شامل وظائف فيسبوك)'),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.blue.shade900,
                  //     foregroundColor: Colors.white,
                  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final req = ServiceRequestModel.fromFirestore(docs[index]);
            return _buildPendingRequestCard(req);
          },
        );
      },
    );
  }

  Widget _buildPendingRequestCard(ServiceRequestModel req) {
    final priceController = TextEditingController(text: req.suggestedBudget > 0 ? req.suggestedBudget.toStringAsFixed(0) : '100');
    final notesController = TextEditingController();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(req.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    req.category,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('العميل: ${req.clientName} | الهاتف: ${req.clientPhone}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            if (req.addressTitle.isNotEmpty) Text('الموقع: ${req.addressTitle}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text('تفاصيل المشكلة: ${req.description}', style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.monetization_on_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text('الميزانية المقترحة من العميل: ${req.suggestedBudget.toStringAsFixed(0)} ${req.effectiveCurrency}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const Divider(height: 20),

            // ملاحظات الأدمن وتعديل السعر
            StatefulBuilder(
              builder: (context, setCardState) {
                final currentEnteredPrice = double.tryParse(priceController.text.trim()) ?? req.suggestedBudget;
                final isModified = currentEnteredPrice != req.suggestedBudget;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'السعر المعتمد (${req.effectiveCurrency})',
                              isDense: true,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.price_change),
                              helperText: isModified ? '⚠️ تم تعديل السعر (سيرسل للعميل للموافقة أولاً)' : '✅ مطابق لسعر العميل (سينشر مباشرة للناس)',
                              helperStyle: TextStyle(color: isModified ? Colors.orange.shade900 : Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            onChanged: (_) => setCardState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (isModified) ...[
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'سبب أو ملاحظة التعديل للعميل (اختياري)', hintText: 'مثال: السعر تم تعديله نظراً لحاجة العمل لمعدات إضافية...', isDense: true, border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
                      ),
                      const SizedBox(height: 10),
                    ],

                    ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final price = double.tryParse(priceController.text.trim()) ?? req.suggestedBudget;
                        final publishedDirectly = await _requestService.adminReviewRequest(requestId: req.id, approvedPrice: price, originalBudget: req.suggestedBudget, adminNotes: notesController.text.trim());
                        if (!mounted) return;
                        if (publishedDirectly) {
                          messenger.showSnackBar(SnackBar(content: Text('تم نشر طلب "${req.title}" مباشرة للناس لأن السعر لم يتغير!'), backgroundColor: Colors.green));
                        } else {
                          messenger.showSnackBar(SnackBar(content: Text('تم إرسال السعر المعدل لـ "${req.clientName}" أولاً للموافقة عليه أو حذفه!'), backgroundColor: Colors.orange.shade800));
                        }
                      },
                      icon: Icon(isModified ? Icons.send : Icons.public, size: 18),
                      label: Text(isModified ? 'إرسال السعر المعدل للعميل أولاً للموافقة' : 'نشر فوري للناس (السعر مطابق دون تعديل)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: isModified ? Colors.orange.shade800 : Colors.green.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 2. تبويب إدارة الفنيين المسجلين
  Widget _buildCraftsmenManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('user').where('role', isEqualTo: 'provider').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('لا يوجد فنيين مسجلين حتى الآن.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final user = UserModel.fromFirestore(docs[index]);
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white, child: Text(user.name.isNotEmpty ? user.name[0] : 'ف')),
                title: Text('${user.name} (${user.profession})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('العمر: ${user.age} سنة | الهاتف: ${user.phone}'),
                trailing: Switch(
                  value: user.isApproved,
                  activeThumbColor: Colors.green,
                  onChanged: (val) async {
                    final messenger = ScaffoldMessenger.of(context);
                    await FirebaseFirestore.instance.collection('user').doc(user.id).update({'isApproved': val});
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text(val ? 'تم تفعيل حساب ${user.name}' : 'تم إيقاف حساب ${user.name}')));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. تبويب إدارة ومزامنة 200 محل ومورد
  Widget _buildSuppliersManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('suppliers').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('إجمالي المحلات في قاعدة البيانات:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              '$count محل',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('قاعدة البيانات مجهزة بأكثر من 1,000 محل ومؤسسة ومركز تكنولوجيا وفنون حقيقية مع إحداثيات خرائط جوجل الدقيقة لكافة المدن.', style: TextStyle(fontSize: 12, height: 1.4)),
                      const SizedBox(height: 16),
                      // ElevatedButton.icon(
                      //   onPressed: _isSeedingSuppliers
                      //       ? null
                      //       : () async {
                      //           setState(() => _isSeedingSuppliers = true);
                      //           final messenger = ScaffoldMessenger.of(context);
                      //           final added = await _supplierService.seedBulkRealSuppliers(force: true);
                      //           if (mounted) {
                      //             setState(() => _isSeedingSuppliers = false);
                      //             messenger.showSnackBar(SnackBar(content: Text('تمت مزامنة وزرع $added محل بنجاح في فايربيز!'), backgroundColor: Colors.green));
                      //           }
                      //         },
                      //   icon: _isSeedingSuppliers ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload),
                      //   label: Text(_isSeedingSuppliers ? 'جاري الاستيراد للفايربيز...' : 'مزامنة وزرع الـ 1,000+ محل الآن'),
                      //   style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('عينة من المحلات المسجلة في منطقتك:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    final s = SupplierModel.fromFirestore(snapshot.data!.docs[index]);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.store, color: Colors.orange.shade900, size: 20),
                        ),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${s.category} | ${s.addressTitle}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          '${s.rating} ★',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
