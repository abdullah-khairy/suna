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
            Tab(icon: Icon(Icons.storefront), text: 'الموردين (200)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingRequestsTab(),
          _buildCraftsmenManagementTab(),
          _buildSuppliersManagementTab(),
        ],
      ),
    );
  }

  // 1. تبويب مراجعة وتسعير طلبات العملاء
  Widget _buildPendingRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_requests')
          .where('status', isEqualTo: RequestStatus.pendingAdmin.name)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.green.shade400),
                const SizedBox(height: 12),
                const Text(
                  'رائع! لا توجد طلبات معلقة حالياً.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'جميع طلبات العملاء تم تسعيرها واعتمادها.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
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
    final priceController = TextEditingController(
      text: req.suggestedBudget > 0 ? req.suggestedBudget.toStringAsFixed(0) : '100',
    );

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
                  child: Text(
                    req.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    req.category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'العميل: ${req.clientName} | الهاتف: ${req.clientPhone}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            if (req.addressTitle.isNotEmpty)
              Text(
                'الموقع: ${req.addressTitle}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'تفاصيل المشكلة: ${req.description}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.monetization_on_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  'الميزانية المقترحة من العميل: ${req.suggestedBudget.toStringAsFixed(0)} ريال',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 24),

            // قسم إدخال واعتماد السعر من الأدمن
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر المعتمد (ريال)',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.price_change),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final price = double.tryParse(priceController.text.trim()) ?? req.suggestedBudget;
                      await _requestService.adminSetPrice(
                        requestId: req.id,
                        approvedPrice: price,
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('تم اعتماد سعر ($price ريال) لطلب "${req.title}" وإرساله للعميل!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('اعتماد وإرسال للعميل', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. تبويب إدارة الفنيين المسجلين
  Widget _buildCraftsmenManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .where('role', isEqualTo: 'provider')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('لا يوجد فنيين مسجلين حتى الآن.'),
          );
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
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  child: Text(user.name.isNotEmpty ? user.name[0] : 'ف'),
                ),
                title: Text(
                  '${user.name} (${user.profession})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('العمر: ${user.age} سنة | الهاتف: ${user.phone}'),
                trailing: Switch(
                  value: user.isApproved,
                  activeThumbColor: Colors.green,
                  onChanged: (val) async {
                    final messenger = ScaffoldMessenger.of(context);
                    await FirebaseFirestore.instance
                        .collection('user')
                        .doc(user.id)
                        .update({'isApproved': val});
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(val ? 'تم تفعيل حساب ${user.name}' : 'تم إيقاف حساب ${user.name}'),
                      ),
                    );
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
                          const Text(
                            'إجمالي المحلات في قاعدة البيانات:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count محل',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'قاعدة البيانات جاهزة ومجهزة بـ 200 محل ومؤسسة حقيقية (رمل وأسمنت، حدايد وبويات، سباكة، وكهرباء) مع إحداثيات خرائط جوجل الدقيقة.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isSeedingSuppliers
                            ? null
                            : () async {
                                setState(() => _isSeedingSuppliers = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final added = await _supplierService.seedBulkRealSuppliers(force: true);
                                if (mounted) {
                                  setState(() => _isSeedingSuppliers = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('تمت مزامنة وزرع $added محل بنجاح في فايربيز!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        icon: _isSeedingSuppliers
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload),
                        label: Text(_isSeedingSuppliers ? 'جاري الاستيراد للفايربيز...' : 'مزامنة وزرع الـ 200 محل الآن'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        ),
                      ),
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
                        trailing: Text('${s.rating} ★', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
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
