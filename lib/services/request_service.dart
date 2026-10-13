import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_request_model.dart';
import '../models/user_model.dart';
// import '../data/real_service_requests_data.dart';
import 'notification_service.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  CollectionReference get _requestsCollection => _firestore.collection('service_requests');

  /// إنشاء طلب خدمة جديد من العميل
  Future<ServiceRequestModel> createRequest(ServiceRequestModel request) async {
    final docRef = _requestsCollection.doc();
    final newRequest = request.copyWith(id: docRef.id);
    await docRef.set(newRequest.toMap());
    return newRequest;
  }

  /// 1. الإدارة: مراجعة الطلب مع فحص التعديل
  /// إذا عدل الأدمن السعر: يذهب للعميل أولاً للموافقة أو الحذف (waitingClientApproval)
  /// إذا لم يعدل الأدمن شيئاً: يُنشر فوراً للناس والصناع (published)
  Future<bool> adminReviewRequest({required String requestId, required double approvedPrice, required double originalBudget, String? adminNotes}) async {
    final bool isPriceModified = (approvedPrice != originalBudget);

    if (isPriceModified) {
      // الأدمن عدل السعر -> يظهر للعميل أولاً مع إشعار للموافقة أو الحذف
      await _requestsCollection.doc(requestId).update({'adminApprovedPrice': approvedPrice, 'adminNotes': adminNotes ?? '', 'isModifiedByAdmin': true, 'status': RequestStatus.waitingClientApproval.name, 'updatedAt': Timestamp.now()});

      // إشعار العميل بتعديل التسعيرة
      try {
        final doc = await _requestsCollection.doc(requestId).get();
        if (doc.exists) {
          final req = ServiceRequestModel.fromFirestore(doc);
          await _notificationService.sendNotification(
            userId: req.clientId,
            title: 'تعديل في تسعيرة طلبك 📝',
            body: 'قام المشرف بمراجعة طلبك "${req.title}" وتعديل الميزانية إلى ${approvedPrice.toStringAsFixed(0)} ${req.effectiveCurrency}. يرجى مراجعته للموافقة أو الإلغاء.',
            type: 'price_modified',
            relatedRequestId: requestId,
          );
        }
      } catch (_) {}

      return false; // لم يُنشر بعد، بانتظار العميل
    } else {
      // الأدمن لم يعدل شيئاً -> يُنشر مباشرة للناس
      await _requestsCollection.doc(requestId).update({'adminApprovedPrice': approvedPrice, 'adminNotes': adminNotes ?? '', 'isModifiedByAdmin': false, 'status': RequestStatus.published.name, 'updatedAt': Timestamp.now()});
      return true; // نُشر مباشرة
    }
  }

  /// دالة متوافقة مع الاستدعاء السابق
  Future<void> adminSetPrice({required String requestId, required double approvedPrice}) async {
    await _requestsCollection.doc(requestId).update({'adminApprovedPrice': approvedPrice, 'status': RequestStatus.waitingClientApproval.name, 'updatedAt': Timestamp.now()});
  }

  /// 2. العميل: الموافقة على تعديل الأدمن ونشر الطلب للناس
  Future<void> clientApprovePrice(String requestId) async {
    await _requestsCollection.doc(requestId).update({'status': RequestStatus.published.name, 'updatedAt': Timestamp.now()});
  }

  /// 3. العميل: رفض تعديل الإدارة أو إلغاء الطلب إذا لم يقبله أحد
  Future<void> clientDeleteOrCancelRequest(String requestId) async {
    await _requestsCollection.doc(requestId).delete();
  }

  /// 4. مقدم الخدمة: قبول الطلب وتسجيل بياناته وإشعار العميل
  Future<void> providerAcceptRequest({required String requestId, required UserModel provider}) async {
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

    // إرسال إشعار فوري للعميل بأن الفني قبل طلبه
    try {
      final doc = await _requestsCollection.doc(requestId).get();
      if (doc.exists) {
        final req = ServiceRequestModel.fromFirestore(doc);
        await _notificationService.sendNotification(
          userId: req.clientId,
          title: 'تم قبول طلبك! 🎉',
          body: 'قام الفني ${provider.name} (${provider.profession.isNotEmpty ? provider.profession : "مغامر"}) بقبول طلبك "${req.title}". يمكنك الآن التواصل معه مباشرة.',
          type: 'accepted',
          relatedRequestId: requestId,
        );
      }
    } catch (_) {}
  }

  /// 5. مقدم الخدمة: الاعتذار عن الخدمة وإعادة طرحها للزملاء وإشعار العميل
  Future<void> providerWithdrawFromRequest({required String requestId, required String providerName}) async {
    final doc = await _requestsCollection.doc(requestId).get();
    if (!doc.exists) return;
    final req = ServiceRequestModel.fromFirestore(doc);

    await _requestsCollection.doc(requestId).update({
      'assignedProviderId': null,
      'assignedProviderName': null,
      'assignedProviderPhone': null,
      'assignedProviderProfession': null,
      'assignedProviderAge': null,
      'assignedProviderRating': null,
      'status': RequestStatus.published.name,
      'updatedAt': Timestamp.now(),
    });

    // إشعار العميل باعتذار الفني وإعادة طرح الخدمة
    try {
      await _notificationService.sendNotification(userId: req.clientId, title: 'اعتذار الفني عن الخدمة ⚠️', body: 'اعتذر الفني $providerName عن تنفيذ طلبك "${req.title}". تمت إعادة طرح الطلب فوراً للبحث عن فني آخر.', type: 'withdrawn', relatedRequestId: requestId);
    } catch (_) {}
  }

  /// 6. بدء تنفيذ الخدمة
  Future<void> startJob(String requestId) async {
    await _requestsCollection.doc(requestId).update({'status': RequestStatus.inProgress.name, 'updatedAt': Timestamp.now()});
  }

  /// 7. الفني: الإشعار بإتمام العمل والطلب من العميل تأكيد الاستلام والتقييم
  Future<void> providerRequestClientConfirmation({required String requestId, required String providerName, required String clientId, required String serviceTitle}) async {
    await _requestsCollection.doc(requestId).update({'status': RequestStatus.waitingClientConfirmation.name, 'updatedAt': Timestamp.now()});

    // إرسال إشعار عاجل للعميل للتأكيد والتقييم
    try {
      await _notificationService.sendNotification(userId: clientId, title: 'يرجى تأكيد تمام الخدمة وتقييم الفني ⭐', body: 'أفاد الفني $providerName بانتهاء تنفيذ طلبك "$serviceTitle". يرجى الدخول لتأكيد استلام العمل وتقييم الفني.', type: 'waitingClientConfirmation', relatedRequestId: requestId);
    } catch (_) {}
  }

  /// 8. العميل: تأكيد تمام الخدمة وتقييم المغامر (مع احتساب النجوم والأرباح)
  Future<void> clientConfirmAndRateService({
    required String requestId,
    required String providerId,
    required double ratingStars,
    String? review,
    required double finalPrice,
    double platformCommissionPercent = 0.10, // عمولة التطبيق 10%
  }) async {
    final doc = await _requestsCollection.doc(requestId).get();
    if (!doc.exists) return;
    final req = ServiceRequestModel.fromFirestore(doc);

    // 1. جلب بيانات الفني الحالية لإعادة حساب متوسط التقييم بدقة
    final providerDoc = await _firestore.collection('user').doc(providerId).get();
    double currentRating = 5.0;
    int currentRatingsCount = 0;
    if (providerDoc.exists) {
      final pData = providerDoc.data() ?? {};
      currentRating = (pData['rating'] is num) ? (pData['rating'] as num).toDouble() : 5.0;
      currentRatingsCount = (pData['ratingsCount'] is num) ? (pData['ratingsCount'] as num).toInt() : 0;
    }

    final int newRatingsCount = currentRatingsCount + 1;
    final double newAverageRating = double.parse((((currentRating * currentRatingsCount) + ratingStars) / newRatingsCount).toStringAsFixed(1));

    final commission = finalPrice * platformCommissionPercent;
    final providerNetEarnings = finalPrice - commission;

    final batch = _firestore.batch();

    // تحديث بيانات وحالة الطلب
    final requestRef = _requestsCollection.doc(requestId);
    batch.update(requestRef, {'status': RequestStatus.completed.name, 'clientRating': ratingStars, 'clientReview': review ?? '', 'isClientConfirmed': true, 'completedAt': Timestamp.now(), 'updatedAt': Timestamp.now()});

    // تحديث بيانات الفني: التقييم الجديد، عدد التقييمات، عدد المهام المكتملة، رصيد المحفظة
    final userRef = _firestore.collection('user').doc(providerId);
    batch.update(userRef, {'rating': newAverageRating, 'ratingsCount': newRatingsCount, 'completedTasksCount': FieldValue.increment(1), 'walletBalance': FieldValue.increment(providerNetEarnings)});

    // إضافة معاملة المحفظة
    final transactionRef = _firestore.collection('wallet_transactions').doc();
    batch.set(transactionRef, {'userId': providerId, 'amount': providerNetEarnings, 'type': 'earning', 'title': 'أجر خدمة مكتملة ومقيمة #$requestId', 'relatedRequestId': requestId, 'createdAt': Timestamp.now()});

    await batch.commit();

    // إرسال إشعار فوري للفني بتأكيد العميل وتقييمه
    try {
      await _notificationService.sendNotification(
        userId: providerId,
        title: 'تم تأكيد الخدمة وتقييمك! ⭐',
        body: 'أكد العميل ${req.clientName} تمام خدمة "${req.title}" وقيمك بـ ${ratingStars.toStringAsFixed(0)} نجوم! تم تحويل $providerNetEarnings ${req.effectiveCurrency} لمحفظتك.',
        type: 'completed',
        relatedRequestId: requestId,
      );
    } catch (_) {}
  }

  /// 9. إتمام الخدمة وتحويل الرصيد إلى محفظة الفني (احتياطي / مباشر)
  Future<void> completeRequest({
    required String requestId,
    required String providerId,
    required double finalPrice,
    double platformCommissionPercent = 0.10, // عمولة التطبيق 10%
  }) async {
    final doc = await _requestsCollection.doc(requestId).get();
    final req = doc.exists ? ServiceRequestModel.fromFirestore(doc) : null;

    final batch = _firestore.batch();

    final requestRef = _requestsCollection.doc(requestId);
    batch.update(requestRef, {'status': RequestStatus.completed.name, 'completedAt': Timestamp.now(), 'updatedAt': Timestamp.now()});

    final commission = finalPrice * platformCommissionPercent;
    final providerNetEarnings = finalPrice - commission;

    final userRef = _firestore.collection('user').doc(providerId);
    batch.update(userRef, {'walletBalance': FieldValue.increment(providerNetEarnings), 'completedTasksCount': FieldValue.increment(1)});

    final transactionRef = _firestore.collection('wallet_transactions').doc();
    batch.set(transactionRef, {'userId': providerId, 'amount': providerNetEarnings, 'type': 'earning', 'title': 'أجر خدمة مكتملة #$requestId', 'relatedRequestId': requestId, 'createdAt': Timestamp.now()});

    await batch.commit();

    // إشعار العميل بإتمام الخدمة
    if (req != null) {
      try {
        await _notificationService.sendNotification(userId: req.clientId, title: 'تم إتمام خدمتك بنجاح ✅', body: 'قام الفني بإنجاز خدمة "${req.title}". نسعد بتقييمك لتجربتك مع النقابة!', type: 'completed', relatedRequestId: requestId);
      } catch (_) {}
    }
  }

  /// جلب كافة الطلبات المتاحة والمنشورة في المنطقة لزوار التطبيق
  Stream<List<ServiceRequestModel>> streamAllPublishedRequests() {
    return _requestsCollection.where('status', isEqualTo: RequestStatus.published.name).snapshots().map((snapshot) => snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).toList());
  }

  /// متابعة جميع طلبات عميل محدد (المنتهية والمطلوبة)
  Stream<List<ServiceRequestModel>> streamClientRequests(String clientId) {
    return _requestsCollection.where('clientId', isEqualTo: clientId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// متابعة الخدمات النشطة التي قبلها فني محدد ولم تكتمل بعد (accepted أو inProgress أو waitingClientConfirmation)
  Stream<List<ServiceRequestModel>> streamProviderActiveAcceptedRequests(String providerId) {
    return _requestsCollection.where('assignedProviderId', isEqualTo: providerId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).where((r) => r.status == RequestStatus.accepted || r.status == RequestStatus.inProgress || r.status == RequestStatus.waitingClientConfirmation).toList();
    });
  }

  /// متابعة الخدمات السابقة التي نفذها وأنهى عملها الفني
  Stream<List<ServiceRequestModel>> streamProviderCompletedRequests(String providerId) {
    return _requestsCollection.where('assignedProviderId', isEqualTo: providerId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ServiceRequestModel.fromFirestore(doc)).where((r) => r.status == RequestStatus.completed).toList();
      list.sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
      return list;
    });
  }

  /// متابعة عدد الطلبات التي تنتظر موافقة العميل على تعديل الإدارة
  Stream<int> streamPendingApprovalCount(String clientId) {
    return _requestsCollection.where('clientId', isEqualTo: clientId).where('status', isEqualTo: RequestStatus.waitingClientApproval.name).snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// متابعة عدد الطلبات التي تنتظر تأكيد وتقييم العميل
  Stream<int> streamPendingConfirmationCount(String clientId) {
    return _requestsCollection.where('clientId', isEqualTo: clientId).where('status', isEqualTo: RequestStatus.waitingClientConfirmation.name).snapshots().map((snapshot) => snapshot.docs.length);
  }

  // /// استيراد وزرع الطلبات الحقيقية للخدمات (48+ طلب من مؤسسات وشركات وعملاء حقيقيين) في فايربيز (Batch Write)
  // Future<int> seedBulkRealServiceRequests({bool force = false}) async {
  //   try {
  //     if (!force) {
  //       final check = await _requestsCollection.limit(30).get();
  //       if (check.docs.length >= 30) {
  //         return check.docs.length;
  //       }
  //     }

  //     const int batchSize = 400;
  //     for (int i = 0; i < kRealServiceRequestsData.length; i += batchSize) {
  //       final end = (i + batchSize < kRealServiceRequestsData.length) ? i + batchSize : kRealServiceRequestsData.length;
  //       final chunk = kRealServiceRequestsData.sublist(i, end);

  //       final batch = _firestore.batch();
  //       for (var req in chunk) {
  //         final docRef = _requestsCollection.doc(req.id);
  //         batch.set(docRef, req.toMap(), SetOptions(merge: true));
  //       }
  //       await batch.commit();
  //     }

  //     return kRealServiceRequestsData.length;
  //   } catch (e) {
  //     debugPrint('Error seeding real service requests: $e');
  //     return 0;
  //   }
  // }

  // /// بذر بيانات فورية للخدمات في حال كانت قاعدة البيانات فارغة أو قديمة
  // Future<void> seedInitialDemoServicesIfEmpty() async {
  //   await seedBulkRealServiceRequests(force: false);
  // }
}
