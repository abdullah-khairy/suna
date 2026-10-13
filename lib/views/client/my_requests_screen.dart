import 'package:flutter/material.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../../services/request_service.dart';
import '../../core/utils/external_launcher.dart';
import '../services/rate_provider_dialog.dart';

class MyRequestsScreen extends StatefulWidget {
  final UserModel currentUser;

  const MyRequestsScreen({super.key, required this.currentUser});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RequestService _requestService = RequestService();

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
        title: const Text('متابعة حالة الخدمات والأعمال', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions, size: 20), text: 'طلباتي الجارية / المطلوبة'),
            Tab(icon: Icon(Icons.task_alt, size: 20), text: 'طلباتي المكتملة'),
            Tab(icon: Icon(Icons.handyman, size: 20), text: 'أعمالي السابقة كمغامر ✅'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. طلباتي الجارية أو التي ما زالت مطلوبة (يمكن إلغاؤها إذا لم يقبلها أحد، أو تأكيد إتمامها وتقييم الفني)
          _buildClientActiveRequestsTab(),

          // 2. طلباتي التي تم إنجازها والانتهاء منها وتقييمها
          _buildClientCompletedRequestsTab(),

          // 3. الأعمال السابقة التي قدمت عليها كمغامر وأنهيتها مع التقييمات
          _buildProviderCompletedJobsTab(),
        ],
      ),
    );
  }

  // تبويب 1: طلبات العميل الجارية أو التي لم يقبلها أحد
  Widget _buildClientActiveRequestsTab() {
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: _requestService.streamClientRequests(widget.currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRequests = snapshot.data ?? [];
        final activeRequests = allRequests.where((r) => r.status != RequestStatus.completed && r.status != RequestStatus.cancelled).toList();

        if (activeRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 65, color: Colors.grey.shade400),
                const SizedBox(height: 14),
                const Text('لا توجد طلبات جارية أو مطلوبة حالياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'عندما تطلب خدمة ستتمكن من متابعتها هنا، أو إلغائها إذا لم يقبلها أحد، أو تأكيدها وتقييم الفني فور انتهائه.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: activeRequests.length,
          itemBuilder: (context, index) {
            return _buildClientRequestCard(activeRequests[index]);
          },
        );
      },
    );
  }

  // تبويب 2: طلبات العميل المكتملة
  Widget _buildClientCompletedRequestsTab() {
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: _requestService.streamClientRequests(widget.currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRequests = snapshot.data ?? [];
        final completedRequests = allRequests.where((r) => r.status == RequestStatus.completed).toList();

        if (completedRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 65, color: Colors.grey.shade400),
                const SizedBox(height: 14),
                const Text('لا توجد طلبات مكتملة حتى الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('الخدمات التي تنتهي وتؤكد تقييمها ستؤرشف هنا للرجوع إليها.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: completedRequests.length,
          itemBuilder: (context, index) {
            return _buildClientRequestCard(completedRequests[index]);
          },
        );
      },
    );
  }

  // تبويب 3: الأعمال التي قدمت عليها كمغامر وأنهيتها
  Widget _buildProviderCompletedJobsTab() {
    return StreamBuilder<List<ServiceRequestModel>>(
      stream: _requestService.streamProviderCompletedRequests(widget.currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedJobs = snapshot.data ?? [];

        if (completedJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handyman_outlined, size: 65, color: Colors.grey.shade400),
                const SizedBox(height: 14),
                const Text('لا توجد أعمال منجزة كمغامر حتى الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'عندما تقبل خدمة وينتهي تنفيذها ويؤكد العميل إتمامها، ستظهر هنا موثقة مع تقييم العميل والأجر المستلم.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: completedJobs.length,
          itemBuilder: (context, index) {
            return _buildProviderCompletedJobCard(completedJobs[index]);
          },
        );
      },
    );
  }

  // كرت طلب العميل
  Widget _buildClientRequestCard(ServiceRequestModel req) {
    final bool isWaitingMyApproval = req.status == RequestStatus.waitingClientApproval;
    final bool isWaitingConfirmation = req.status == RequestStatus.waitingClientConfirmation;
    final bool isCompleted = req.status == RequestStatus.completed;
    final bool isStillLooking = req.status == RequestStatus.published;
    final bool isPendingAdmin = req.status == RequestStatus.pendingAdmin;
    final bool isAssigned = req.status == RequestStatus.accepted || req.status == RequestStatus.inProgress || req.status == RequestStatus.waitingClientConfirmation;

    // هل يمكن للعميل إلغاء الطلب؟ (إذا لم يقبله أحد بعد)
    final bool canCancel = (isStillLooking || isPendingAdmin || isWaitingMyApproval) && (req.assignedProviderId == null);

    Color statusColor = Colors.blue;
    if (isWaitingMyApproval) statusColor = Colors.orange.shade800;
    if (isWaitingConfirmation) statusColor = Colors.amber.shade900;
    if (isCompleted) statusColor = Colors.green;
    if (isStillLooking) statusColor = Colors.teal;
    if (isAssigned && !isWaitingConfirmation && !isCompleted) statusColor = Colors.indigo;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isWaitingConfirmation || isWaitingMyApproval ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isWaitingConfirmation ? Colors.amber.shade600 : (isWaitingMyApproval ? Colors.orange.shade400 : Colors.grey.shade200), width: isWaitingConfirmation || isWaitingMyApproval ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان + شارة الحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(req.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    req.status.titleAr,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('التصنيف: ${req.category}  |  تاريخ الطلب: ${req.createdAt.year}/${req.createdAt.month}/${req.createdAt.day}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(req.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.3)),
            const Divider(height: 20),

            // ⚠️ في حال عدل الأدمن السعر وبانتظار موافقة العميل
            if (isWaitingMyApproval) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notification_important, color: Colors.orange.shade900, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'تنبيه: قام الأدمن بمراجعة وتعديل تسعيرة الخدمة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('السعر المقترح منك: ${req.suggestedBudget.toStringAsFixed(0)} ${req.effectiveCurrency}'),
                        Text(
                          'السعر المعدل: ${req.adminApprovedPrice?.toStringAsFixed(0)} ${req.effectiveCurrency}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 14),
                        ),
                      ],
                    ),
                    if (req.adminNotes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'ملاحظة الإدارة: ${req.adminNotes}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await _requestService.clientApprovePrice(req.id);
                              messenger.showSnackBar(const SnackBar(content: Text('تمت الموافقة على تعديل السعر ونشر الخدمة للصناع فوراً!'), backgroundColor: Colors.green));
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('موافقة ونشر للناس'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmCancelRequest(req),
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            label: const Text('رفض وحذف الطلب', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // عرض السعر وحالة العثور على فني
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('السعر: ${(req.adminApprovedPrice ?? req.suggestedBudget).toStringAsFixed(0)} ${req.effectiveCurrency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (isStillLooking)
                    const Text('⏳ ما زال مطلوباً (بانتظار قبول مغامر)', style: TextStyle(color: Colors.teal, fontSize: 12))
                  else if (isPendingAdmin)
                    const Text('⏳ قيد تدقيق الإدارة', style: TextStyle(color: Colors.blue, fontSize: 12))
                  else if (isCompleted)
                    const Text(
                      'مكتملة ومُنجزة ✓',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                ],
              ),

              // إذا تم قبول الطلب من فني
              if (isAssigned && req.assignedProviderName != null) ...[
                const SizedBox(height: 12),

                // تنبيه خاص إذا أفاد الفني بانتهاء العمل
                if (isWaitingConfirmation)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars, color: Colors.amber.shade900, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('أفاد الفني بانتهاء العمل! يرجى تأكيد استلام الخدمة وتقييم الفني.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.handyman, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('المغامر: ${req.assignedProviderName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('المهنة: ${req.assignedProviderProfession ?? 'مهني متخصص'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                if (req.assignedProviderPhone != null) Text('الهاتف: ${req.assignedProviderPhone}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          if (req.assignedProviderPhone != null)
                            ElevatedButton.icon(
                              onPressed: () => ExternalLauncher.makePhoneCall(req.assignedProviderPhone!),
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text('اتصال'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            ),
                        ],
                      ),

                      // زر تأكيد تمام الخدمة وتقييم الفني (متاح للعميل طالما الخدمة لم تكتمل بعد)
                      if (!isCompleted) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => RateProviderDialog(request: req, onRated: () => setState(() {})),
                              );
                            },
                            icon: const Icon(Icons.star, color: Colors.amber, size: 18),
                            label: const Text('تأكيد تمام الخدمة وتقييم الفني ⭐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // إذا كانت الخدمة مكتملة ومقيمة مسبقاً، عرض التقييم المسجل
              if (isCompleted && req.clientRating != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              final filled = (i + 1) <= req.clientRating!.round();
                              return Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber.shade700, size: 18);
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تقييمك: ${req.clientRating!.toStringAsFixed(0)} / 5 نجوم',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                          ),
                        ],
                      ),
                      if (req.clientReview != null && req.clientReview!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'تعليقك: "${req.clientReview}"',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // إذا لم يقبلها أحد بعد: يتاح للعميل خيار إلغاء الطلب
              if (canCancel) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _confirmCancelRequest(req),
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                      label: const Text(
                        'إلغاء الطلب',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // كرت العمل المنجز كمغامر
  Widget _buildProviderCompletedJobCard(ServiceRequestModel req) {
    final price = req.finalPrice ?? req.adminApprovedPrice ?? req.suggestedBudget;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(req.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'منجزة ومستلمة ✅',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('التصنيف: ${req.category}  |  العميل: ${req.clientName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            if (req.addressTitle.isNotEmpty) Text('الموقع: ${req.addressTitle}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

            // تقييم العميل الممنوح للفني
            if (req.clientRating != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final filled = (i + 1) <= req.clientRating!.round();
                        return Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber.shade700, size: 17);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تقييم العميل: ${req.clientRating!.toStringAsFixed(0)} / 5 نجوم',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                    ),
                    if (req.clientReview != null && req.clientReview!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"${req.clientReview}"',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'الأجر المستحق: ${price.toStringAsFixed(0)} ${req.effectiveCurrency}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade900),
                    ),
                  ],
                ),
                Text(req.completedAt != null ? '${req.completedAt!.year}/${req.completedAt!.month}/${req.completedAt!.day}' : '${req.createdAt.year}/${req.createdAt.month}/${req.createdAt.day}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // تأكيد إلغاء وحذف الطلب
  Future<void> _confirmCancelRequest(ServiceRequestModel req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد إلغاء الطلب'),
        content: Text('هل أنت متأكد من رغبتك في إلغاء وحذف طلب "${req.title}"؟ لن يظهر للصناع بعد الآن.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await _requestService.clientDeleteOrCancelRequest(req.id);
      messenger.showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب بنجاح.'), backgroundColor: Colors.red));
    }
  }
}
