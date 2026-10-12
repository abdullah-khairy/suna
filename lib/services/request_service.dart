import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_request_model.dart';
import '../models/user_model.dart';
import '../core/services/location_service.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _requestsCollection =>
      _firestore.collection('service_requests');

  /// إنشاء طلب خدمة جديد من العميل
  Future<ServiceRequestModel> createRequest(ServiceRequestModel request) async {
    final docRef = _requestsCollection.doc();
    final newRequest = request.copyWith(id: docRef.id);
    await docRef.set(newRequest.toMap());
    return newRequest;
  }

  /// 1. الإدارة: مراجعة الطلب ووضع/تعديل التسعيرة المعتمدة
  Future<void> adminSetPrice({
    required String requestId,
    required double approvedPrice,
  }) async {
    await _requestsCollection.doc(requestId).update({
      'adminApprovedPrice': approvedPrice,
      'status': RequestStatus.waitingClientApproval.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// 2. العميل: الموافقة على تسعيرة الإدارة ونشر الطلب
  Future<void> clientApprovePrice(String requestId) async {
    await _requestsCollection.doc(requestId).update({
      'status': RequestStatus.published.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// 3. مقدم الخدمة: قبول الطلب وتسجيل بياناته
  Future<void> providerAcceptRequest({
    required String requestId,
    required UserModel provider,
  }) async {
    await _requestsCollection.doc(requestId).update({
      'assignedProviderId': provider.id,
      'assignedProviderName': provider.name,
      'assignedProviderPhone': provider.phone,
      'assignedProviderProfession': provider.profession,
      'assignedProviderAge': provider.age,
      'assignedProviderRating': provider.rating,
      'status': RequestStatus.accepted.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// 4. بدء تنفيذ الخدمة
  Future<void> startJob(String requestId) async {
    await _requestsCollection.doc(requestId).update({
      'status': RequestStatus.inProgress.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// 5. إتمام الخدمة وتحويل الرصيد إلى محفظة الفني
  Future<void> completeRequest({
    required String requestId,
    required String providerId,
    required double finalPrice,
    double platformCommissionPercent = 0.10, // عمولة التطبيق 10%
  }) async {
    final batch = _firestore.batch();

    final requestRef = _requestsCollection.doc(requestId);
    batch.update(requestRef, {
      'status': RequestStatus.completed.name,
      'completedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    final commission = finalPrice * platformCommissionPercent;
    final providerNetEarnings = finalPrice - commission;

    final userRef = _firestore.collection('user').doc(providerId);
    batch.update(userRef, {
      'walletBalance': FieldValue.increment(providerNetEarnings),
      'completedTasksCount': FieldValue.increment(1),
    });

    final transactionRef = _firestore.collection('wallet_transactions').doc();
    batch.set(transactionRef, {
      'userId': providerId,
      'amount': providerNetEarnings,
      'type': 'earning',
      'title': 'أجر خدمة مكتملة #$requestId',
      'relatedRequestId': requestId,
      'createdAt': Timestamp.now(),
    });

    await batch.commit();
  }

  /// جلب كافة الطلبات المتاحة والمنشورة في المنطقة لزوار التطبيق
  Stream<List<ServiceRequestModel>> streamAllPublishedRequests() {
    return _requestsCollection
        .where('status', isEqualTo: RequestStatus.published.name)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).toList());
  }

  /// جلب الطلبات المنشورة القريبة والمطابقة للتخصص الجغرافي
  Future<List<Map<String, dynamic>>> getNearbyRequestsWithDistance({
    required GeoPoint providerLocation,
    String? profession,
    double maxRadiusKm = 25.0,
  }) async {
    Query query = _requestsCollection.where(
      'status',
      isEqualTo: RequestStatus.published.name,
    );

    if (profession != null && profession.isNotEmpty) {
      query = query.where('category', isEqualTo: profession);
    }

    final querySnapshot = await query.get();
    final List<Map<String, dynamic>> results = [];

    for (var doc in querySnapshot.docs) {
      final request = ServiceRequestModel.fromFirestore(doc);
      if (request.clientLocation != null) {
        final distanceKm = LocationService.calculateDistanceInKm(
          providerLocation,
          request.clientLocation!,
        );

        if (distanceKm <= maxRadiusKm) {
          results.add({
            'request': request,
            'distanceKm': distanceKm,
            'formattedDistance': LocationService.formatDistance(distanceKm),
          });
        }
      } else {
        results.add({
          'request': request,
          'distanceKm': 0.0,
          'formattedDistance': 'في نطاقك',
        });
      }
    }

    results.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    return results;
  }

  /// متابعة طلبات العميل الحية
  Stream<List<ServiceRequestModel>> streamClientRequests(String clientId) {
    return _requestsCollection
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).toList());
  }

  /// متابعة الطلبات المعينة لفني
  Stream<List<ServiceRequestModel>> streamProviderAssignedRequests(String providerId) {
    return _requestsCollection
        .where('assignedProviderId', isEqualTo: providerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).toList());
  }

  /// بذر بيانات تجريبية فورية للخدمات في المنطقة في حال كانت قاعدة البيانات فارغة
  Future<void> seedInitialDemoServicesIfEmpty() async {
    try {
      final check = await _requestsCollection.limit(1).get();
      if (check.docs.isNotEmpty) return;

      final demoServices = [
        ServiceRequestModel(
          id: 'demo_req_1',
          clientId: 'client_demo_1',
          clientName: 'أبو فهد',
          clientPhone: '0559988771',
          clientLocation: const GeoPoint(24.7136, 46.6753),
          addressTitle: 'حي الملقا، الرياض',
          category: 'سباكة',
          title: 'إصلاح تسريب مياه في المطبخ وتركيب خلاط',
          description: 'يوجد تسريب تحت حوض المطبخ يحتاج تغيير مواسير الصرف وتركيب خلاط مياه جديد متوفر لدي.',
          suggestedBudget: 150.0,
          adminApprovedPrice: 150.0,
          status: RequestStatus.published,
          createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
        ServiceRequestModel(
          id: 'demo_req_2',
          clientId: 'client_demo_2',
          clientName: 'سارة خالد',
          clientPhone: '0501122334',
          clientLocation: const GeoPoint(24.7200, 46.6800),
          addressTitle: 'حي الياسمين، الرياض',
          category: 'كهرباء',
          title: 'صيانة قاطع كهرباء رئيسي وإضاءة الصالة',
          description: 'القاطع الكهربائي الرئيسي يفصل باستمرار عند تشغيل المكيف، وفحص أسلاك لوحة التوزيع.',
          suggestedBudget: 200.0,
          adminApprovedPrice: 200.0,
          status: RequestStatus.published,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        ServiceRequestModel(
          id: 'demo_req_3',
          clientId: 'client_demo_3',
          clientName: 'عبدالله السعيد',
          clientPhone: '0544332211',
          clientLocation: const GeoPoint(24.7050, 46.6600),
          addressTitle: 'حي النرجس، الرياض',
          category: 'تكييف وتبريد',
          title: 'تنظيف وغسيل 3 مكيفات سبليت وشحن فريون',
          description: 'مكيفات سبليت تحتاج تنظيف عميق بالضغط العالي وفحص نسبة الفريون قبل دخول الصيف.',
          suggestedBudget: 350.0,
          adminApprovedPrice: 350.0,
          status: RequestStatus.published,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      for (var req in demoServices) {
        await _requestsCollection.doc(req.id).set(req.toMap());
      }
    } catch (_) {}
  }
}
