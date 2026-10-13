import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_model.dart';
import 'models/service_request_model.dart';
import 'models/category_model.dart';
import 'services/auth_service.dart';
import 'services/request_service.dart';
import 'services/supplier_service.dart';
import 'services/notification_service.dart';
import 'core/services/location_service.dart';
import 'core/utils/external_launcher.dart';
import 'views/common/craftsman_header_card.dart';
import 'views/auth/auth_dialog.dart';
import 'views/services/service_details_dialog.dart';
import 'views/client/create_request_sheet.dart';
import 'views/client/my_requests_screen.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'views/suppliers/suppliers_view.dart';
import 'views/suppliers/add_supplier_sheet.dart';
import 'views/notifications/notifications_screen.dart';
import 'views/widgets/ads/app_ad_banner.dart';

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
  final NotificationService _notificationService = NotificationService();

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
      // 2. استرجاع المستخدم المسجل مسبقاً إن وجد
      _currentUser = await _authService.getCurrentUser();

      // 3. جلب موقع الجهاز للفرز الجغرافي
      _deviceLocation = await LocationService.getCurrentLocation();

      // // 4. بذر طلبات تجريبية ومحلات تجريبية في حال كانت قاعدة البيانات فارغة لتظهر فوراً
      // await _requestService.seedInitialDemoServicesIfEmpty();
      // await _supplierService.seedInitialDemoSuppliersIfEmpty();
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

  void _openMyRequestsScreen() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول أولاً للوصول لطلباتك')));
      _openAuthDialog();
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => MyRequestsScreen(currentUser: _currentUser!))).then((_) => setState(() {}));
  }

  void _openNotificationsScreen() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول لعرض الإشعارات والتنبيهات')));
      _openAuthDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(userId: _currentUser!.id, currentUser: _currentUser),
      ),
    ).then((_) => setState(() {}));
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
            Image.asset('images/sannaLogo.png', width: 30, height: 30, fit: BoxFit.contain, semanticLabel: 'إشعارات النقابة'),
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

          // زر مركز الإشعارات 🔔 مع عدد الإشعارات غير المقروءة
          if (_currentUser != null)
            StreamBuilder<int>(
              stream: _notificationService.streamUnreadCount(_currentUser!.id),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    backgroundColor: Colors.amber.shade700,
                    child: const Icon(Icons.notifications_outlined, color: Colors.white),
                  ),
                  tooltip: 'مركز الإشعارات والتنبيهات',
                  onPressed: _openNotificationsScreen,
                );
              },
            ),

          // زر "طلباتي ومتابعة حالتها" مع إشعار باللون الأحمر إذا كان هناك تعديل يحتاج موافقة
          if (_currentUser != null)
            StreamBuilder<int>(
              stream: _requestService.streamPendingApprovalCount(_currentUser!.id),
              builder: (context, snapshot) {
                final pendingCount = snapshot.data ?? 0;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: pendingCount > 0,
                    label: Text('$pendingCount'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.assignment, color: Colors.white),
                  ),
                  tooltip: 'متابعة الطلبات والأعمال السابقة',
                  onPressed: _openMyRequestsScreen,
                );
              },
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
                    _openMyRequestsScreen();
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppAdBanner(placement: AdPlacement.bottomAnchor),
          BottomNavigationBar(
            currentIndex: _currentNavIndex,
            selectedItemColor: Colors.blue.shade900,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() => _currentNavIndex = index);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.handyman_outlined), activeIcon: Icon(Icons.handyman), label: 'طلبات الخدمات'),
              BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'المون والمحلات القريبة'),
            ],
          ),
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

        // ⚠️ إشعار عاجل للعميل إذا قام الأدمن بتعديل تسعيرة أي من طلباته
        if (_currentUser != null)
          StreamBuilder<int>(
            stream: _requestService.streamPendingApprovalCount(_currentUser!.id),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;
              if (pendingCount == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());

              return SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.shade400, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notification_important, color: Colors.orange.shade900, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إشعار: لديك ($pendingCount) طلب تم تعديل تسعيرته من الإدارة!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade900),
                            ),
                            const Text('اضغط هنا لمراجعة السعر الجديد والموافقة عليه أو حذف الطلب.', style: TextStyle(fontSize: 11, color: Colors.black87)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _openMyRequestsScreen,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        child: const Text('مراجعة الآن'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // 🌟 إشعار للعميل لتأكيد تمام الخدمة وتقييم الفني
        if (_currentUser != null)
          StreamBuilder<int>(
            stream: _requestService.streamPendingConfirmationCount(_currentUser!.id),
            builder: (context, snapshot) {
              final confirmCount = snapshot.data ?? 0;
              if (confirmCount == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());

              return SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade400, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars_rounded, color: Colors.green.shade900, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إشعار: لديك ($confirmCount) خدمة بانتظار تأكيدك وتقييم الفني!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                            ),
                            const Text('أفاد الفني بإتمام العمل؛ يرجى تأكيد الاستلام وتقييم التجربة.', style: TextStyle(fontSize: 11, color: Colors.black87)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _openMyRequestsScreen,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        child: const Text('تأكيد وتقييم ⭐'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // 1. الكارت العلوي لطلب بيانات المغامر (الاسم، المهنة، العمر) أو عرض حسابه المعتمد
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

        // 2. كارت الخدمة المقبولة الجارية تحت كارت اليوزر مباشرة (مع إمكانية الاعتذار عنها أو إنهائها)
        if (_currentUser != null)
          StreamBuilder<List<ServiceRequestModel>>(
            stream: _requestService.streamProviderActiveAcceptedRequests(_currentUser!.id),
            builder: (context, snapshot) {
              final activeJobs = snapshot.data ?? [];
              if (activeJobs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildActiveAcceptedJobCard(activeJobs[index]);
                  }, childCount: activeJobs.length),
                ),
              );
            },
          ),

        // زر وصول سريع لشاشة "متابعة الحالة" للعميل والمغامر
        if (_currentUser != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: OutlinedButton.icon(
                onPressed: _openMyRequestsScreen,
                icon: const Icon(Icons.history, size: 18),
                label: const Text('متابعة الحالة (الطلبات والأعمال السابقة المنجزة)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade900,
                  side: BorderSide(color: Colors.blue.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

        // 3. شريط فلاتر التصنيفات السريعة (سباكة، كهرباء، تكييف...)
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
                    TextButton(
                      onPressed: () async {
                        _deviceLocation = await LocationService.getCurrentLocation();
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.near_me, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(_deviceLocation != null ? 'قريب منك' : 'جميع المناطق', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                        ],
                      ),
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

        // 4. قائمة الخدمات المنشورة في المنطقة
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
                  // عرض إعلان غير مزعج بعد كل 5 كروت في الخلاصة
                  final bool showAdAfterThis = (index > 0 && index % 5 == 0);
                  if (showAdAfterThis) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildServiceCard(req),
                        const AppAdBanner(placement: AdPlacement.feedInline),
                      ],
                    );
                  }
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

  // كرت الخدمة المقبولة والجارية التي تظهر تحت كارت اليوزر مباشرة
  Widget _buildActiveAcceptedJobCard(ServiceRequestModel job) {
    final price = job.finalPrice ?? job.adminApprovedPrice ?? job.suggestedBudget;
    final bool isWaitingConfirmation = job.status == RequestStatus.waitingClientConfirmation;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isWaitingConfirmation ? Colors.amber.shade700 : Colors.blue.shade700, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [isWaitingConfirmation ? Colors.amber.shade50.withValues(alpha: 0.6) : Colors.blue.shade50.withValues(alpha: 0.6), Colors.white], begin: Alignment.topRight, end: Alignment.bottomLeft),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة الكرت
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: isWaitingConfirmation ? Colors.amber.shade900 : Colors.blue.shade900, shape: BoxShape.circle),
                      child: const Icon(Icons.handyman, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'خدمة قبلتها وجاري تنفيذها',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWaitingConfirmation ? Colors.amber.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isWaitingConfirmation ? Colors.amber.shade400 : Colors.blue.shade300),
                  ),
                  child: Text(
                    isWaitingConfirmation ? 'بانتظار تقييم العميل ⏳' : 'قيد التنفيذ 🛠️',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isWaitingConfirmation ? Colors.amber.shade900 : Colors.blue.shade900),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // عنوان الخدمة وسعرها
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Text(
                  '${price.toStringAsFixed(0)} ${job.effectiveCurrency}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('التصنيف: ${job.category}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 12),

            // بيانات العميل المباشرة والاتصال والموقع
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin, color: Colors.blue, size: 18),
                      const SizedBox(width: 6),
                      Text('العميل: ${job.clientName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (job.addressTitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(job.addressTitle, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ExternalLauncher.makePhoneCall(job.clientPhone),
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('اتصال بالعميل'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                        ),
                      ),
                      if (job.clientLocation != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => ExternalLauncher.openGoogleMaps(latitude: job.clientLocation!.latitude, longitude: job.clientLocation!.longitude),
                            icon: const Icon(Icons.directions, size: 16),
                            label: const Text('الموقع بالخريطة'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade900,
                              side: BorderSide(color: Colors.blue.shade800),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // زرا الإجراءات: الاعتذار عن الخدمة + إتمام الخدمة بنجاح
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmWithdrawJob(job),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    label: const Text(
                      'الاعتذار عنها',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isWaitingConfirmation ? null : () => _confirmCompleteJob(job, price),
                    icon: Icon(isWaitingConfirmation ? Icons.hourglass_top : Icons.check_circle_outline, size: 18),
                    label: Text(isWaitingConfirmation ? 'بانتظار تقييم العميل ⏳' : 'أنهيت العمل (طلب التأكيد) ✅', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWaitingConfirmation ? Colors.amber.shade800 : Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // تأكيد الاعتذار عن الخدمة
  Future<void> _confirmWithdrawJob(ServiceRequestModel job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الاعتذار عن تنفيذ الخدمة'),
        content: Text('هل أنت متأكد من الاعتذار عن خدمة "${job.title}"؟\n\nسيتم إعادة طرحها للزملاء المغامرة الآخرين فوراً، وإشعار العميل بذلك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الاعتذار', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && _currentUser != null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await _requestService.providerWithdrawFromRequest(requestId: job.id, providerName: _currentUser!.name);
      messenger.showSnackBar(const SnackBar(content: Text('تم الاعتذار عن الخدمة وإعادتها لقائمة الطلبات المتاحة للزملاء.'), backgroundColor: Colors.orange));
      setState(() {});
    }
  }

  // إشعار العميل بانتهاء العمل وطلب التأكيد والتقييم
  Future<void> _confirmCompleteJob(ServiceRequestModel job, double price) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إشعار العميل بانتهاء العمل'),
        content: Text('هل تم إنجاز العمل بالكامل لخدمة "${job.title}"؟\n\nسيتم إشعار العميل فوراً لتأكيد استلام الخدمة وتقييمك وإيداع الأجر في محفظتك.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد وإشعار العميل ✅', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && _currentUser != null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await _requestService.providerRequestClientConfirmation(requestId: job.id, providerName: _currentUser!.name, clientId: job.clientId, serviceTitle: job.title);
      messenger.showSnackBar(const SnackBar(content: Text('تم إرسال إشعار للعميل لتأكيد استلام الخدمة وتقييمك!'), backgroundColor: Colors.green));
      setState(() {});
    }
  }

  // بناء شريحة تصنيف الخدمة
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

  // بناء كرت الخدمة في قائمة الطلبات
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
                    '$price ${req.effectiveCurrency}',
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
                    onPressed: () {
                      _openServiceDetails(req);
                    },
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
