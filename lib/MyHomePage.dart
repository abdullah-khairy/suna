import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_model.dart';
import 'models/service_request_model.dart';
import 'models/category_model.dart';
import 'services/auth_service.dart';
import 'services/request_service.dart';
import 'services/supplier_service.dart';
import 'core/services/location_service.dart';
import 'views/common/craftsman_header_card.dart';
import 'views/auth/auth_dialog.dart';
import 'views/services/service_details_dialog.dart';
import 'views/client/create_request_sheet.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'views/suppliers/suppliers_view.dart';
import 'views/suppliers/add_supplier_sheet.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AuthService _authService = AuthService();
  final RequestService _requestService = RequestService();
  final SupplierService _supplierService = SupplierService();

  UserModel? _currentUser;
  bool _isLoading = true;
  String _selectedCategoryFilter = 'الكل';
  GeoPoint? _deviceLocation;
  int _currentNavIndex = 0; // 0: طلبات الخدمات, 1: محلات المون والموردين

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);

    try {
      // 1. زرع حساب الإدارة التجريبي ليعمل مباشرة
      await _authService.seedAdminAccountIfMissing();

      // 2. استرجاع المستخدم المسجل مسبقاً إن وجد
      _currentUser = await _authService.getCurrentUser();

      // 3. جلب موقع الجهاز للفرز الجغرافي
      _deviceLocation = await LocationService.getCurrentLocation();

      // 4. بذر طلبات تجريبية ومحلات تجريبية في حال كانت قاعدة البيانات فارغة لتظهر فوراً
      await _requestService.seedInitialDemoServicesIfEmpty();
      await _supplierService.seedInitialDemoSuppliersIfEmpty();
    } catch (_) {
      // التعامل بسلاسة مع عدم توفر اتصال
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openAuthDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AuthDialog(
        onAuthSuccess: (user) {
          setState(() => _currentUser = user);
        },
      ),
    );
  }

  void _openAdminDashboard() {
    if (_currentUser == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboardScreen(adminUser: _currentUser!))).then((_) => setState(() {}));
  }

  void _openCreateRequestSheet() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول أولاً لطلب خدمة')));
      _openAuthDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => CreateRequestSheet(currentUser: _currentUser!, onRequestCreated: () => setState(() {})),
    );
  }

  void _openAddSupplierSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => AddSupplierSheet(onSupplierAdded: () => setState(() {})),
    );
  }

  void _openServiceDetails(ServiceRequestModel request) {
    showDialog(
      context: context,
      builder: (ctx) => ServiceDetailsDialog(
        request: request,
        currentUser: _currentUser,
        onLoginRequired: (user) {
          setState(() => _currentUser = user);
        },
        onAccepted: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('images/sannaLogo.png', width: 30, height: 30, fit: BoxFit.contain, semanticLabel: 'شعار صنعه'),
            const SizedBox(width: 8),
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر درع الإدارة إذا كان مسجلاً كمسؤول
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 26),
              tooltip: 'لوحة تحكم الإدارة',
              onPressed: _openAdminDashboard,
            ),

          if (_currentUser == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _openAuthDialog,
                icon: const Icon(Icons.login, size: 16),
                label: const Text('تسجيل الدخول'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.blue.shade900,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ActionChip(
                avatar: Icon(isAdmin ? Icons.shield : Icons.person, size: 16, color: isAdmin ? Colors.amber.shade800 : Colors.blue),
                label: Text(_currentUser!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                backgroundColor: Colors.white,
                onPressed: () {
                  if (isAdmin) {
                    _openAdminDashboard();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مسجل كـ ${_currentUser!.name} (${_currentUser!.role.nameAr})')));
                  }
                },
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _bootstrap,
              child: _currentNavIndex == 0 ? _buildServicesFeed(isAdmin) : SuppliersView(userLocation: _deviceLocation, onAddSupplierPressed: _openAddSupplierSheet),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'طلبات الخدمات'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'المون والمحلات القريبة'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _currentNavIndex == 0 ? _openCreateRequestSheet : _openAddSupplierSheet,
        backgroundColor: _currentNavIndex == 0 ? Colors.blue.shade900 : Colors.orange.shade800,
        foregroundColor: Colors.white,
        icon: Icon(_currentNavIndex == 0 ? Icons.add : Icons.add_business),
        label: Text(_currentNavIndex == 0 ? 'أطلب خدمة الآن' : 'أضف محلك كمورد مون', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // الواجهة الرئيسية لطلبات الخدمات
  Widget _buildServicesFeed(bool isAdmin) {
    return CustomScrollView(
      slivers: [
        // شريط تنبيه خاص بمدير النظام
        if (isAdmin)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('أنت مسجل كـ "مسؤول النظام"', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('يمكنك مراجعة وتسعير طلبات العملاء وإدارة الفنيين', style: TextStyle(fontSize: 11, color: Colors.black87)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _openAdminDashboard,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    child: const Text('لوحة الإدارة'),
                  ),
                ],
              ),
            ),
          ),

        // 1. الكارت العلوي لطلب بيانات الصنايعي (الاسم، المهنة، العمر) أو عرض حسابه المعتمد
        SliverToBoxAdapter(
          child: CraftsmanHeaderCard(
            currentUser: _currentUser,
            onUserUpdated: (user) {
              setState(() => _currentUser = user);
            },
            onLogout: () async {
              await _authService.logout();
              setState(() => _currentUser = null);
            },
          ),
        ),

        // 2. شريط فلاتر التصنيفات السريعة (سباكة، كهرباء، تكييف...)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الخدمات المطلوبة في منطقتك:',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.near_me, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(_deviceLocation != null ? 'قريب منك' : 'جميع المناطق', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [_buildCategoryChip('الكل'), ...ServiceCategory.defaultCategories.map((c) => _buildCategoryChip(c.name))]),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // 3. قائمة الخدمات المنشورة في المنطقة
        StreamBuilder<List<ServiceRequestModel>>(
          stream: _requestService.streamAllPublishedRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final allRequests = snapshot.data ?? [];

            final filteredRequests = _selectedCategoryFilter == 'الكل' ? allRequests : allRequests.where((r) => r.category == _selectedCategoryFilter).toList();

            if (filteredRequests.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 55, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(_selectedCategoryFilter == 'الكل' ? 'لا توجد خدمات مطلوبة في منطقتك حالياً.' : 'لا توجد طلبات في تصنيف "$_selectedCategoryFilter" حالياً.', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final req = filteredRequests[index];
                  return _buildServiceCard(req);
                }, childCount: filteredRequests.length),
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildCategoryChip(String title) {
    final isSelected = _selectedCategoryFilter == title;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(title),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        selectedColor: Colors.blue.shade900,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        onSelected: (val) {
          setState(() => _selectedCategoryFilter = title);
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceRequestModel req) {
    final price = req.adminApprovedPrice ?? req.suggestedBudget;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _openServiceDetails(req),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.handyman_outlined, size: 14, color: Colors.blue.shade900),
                        const SizedBox(width: 6),
                        Text(
                          req.category,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$price ريال',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(req.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              Text(
                req.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(req.addressTitle.isNotEmpty ? req.addressTitle : 'المنطقة القريبة منك', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _openServiceDetails(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('تفاصيل وقبول الخدمة', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
