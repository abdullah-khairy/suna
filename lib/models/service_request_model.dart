import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/currency_helper.dart';

enum RequestStatus {
  pendingAdmin, // بانتظار مراجعة وتسعير الإدارة
  waitingClientApproval, // تم التعديل من الإدارة وبانتظار موافقة العميل
  published, // معتمد ومنشور للفنيين (ما زال مطلوباً)
  accepted, // تم قبول الطلب من فني محدد
  inProgress, // جاري تنفيذ العمل في موقع العميل
  waitingClientConfirmation, // الفني أنهى العمل وبانتظار تأكيد وتقييم العميل
  completed, // تم تأكيد إتمام العمل والتقييم بنجاح
  cancelled, // تم إلغاء أو حذف الطلب
}

extension RequestStatusExtension on RequestStatus {
  String get titleAr {
    switch (this) {
      case RequestStatus.pendingAdmin:
        return 'قيد مراجعة الإدارة';
      case RequestStatus.waitingClientApproval:
        return 'بانتظار موافقتك على تعديل الإدارة';
      case RequestStatus.published:
        return 'منشور (ما زال مطلوباً)';
      case RequestStatus.accepted:
        return 'تم القبول من فني';
      case RequestStatus.inProgress:
        return 'جاري التنفيذ';
      case RequestStatus.waitingClientConfirmation:
        return 'بانتظار تأكيد وتقييم العميل ⏳';
      case RequestStatus.completed:
        return 'تم الانتهاء والتقييم بنجاح ✅';
      case RequestStatus.cancelled:
        return 'ملغي / محذوف';
    }
  }

  static RequestStatus fromString(String? str) {
    switch (str) {
      case 'waitingClientApproval':
        return RequestStatus.waitingClientApproval;
      case 'published':
        return RequestStatus.published;
      case 'accepted':
        return RequestStatus.accepted;
      case 'inProgress':
        return RequestStatus.inProgress;
      case 'waitingClientConfirmation':
        return RequestStatus.waitingClientConfirmation;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      default:
        return RequestStatus.pendingAdmin;
    }
  }
}

class ServiceRequestModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final GeoPoint? clientLocation;
  final String addressTitle;

  // Service details
  final String category; // مثل: سباكة، كهرباء، صيانة أجهزة...
  final String title;
  final String description;
  final List<String> imageUrls;

  // Pricing & Admin modifications
  final double suggestedBudget; // السعر المقترح من العميل
  final double? adminApprovedPrice; // السعر المحدد من الإدارة
  final double? finalPrice; // السعر النهائي المتفق عليه
  final String adminNotes; // ملاحظات أو سبب التعديل من الإدارة
  final bool isModifiedByAdmin; // هل عدل الأدمن السعر أو المواصفات؟
  final String currency; // رمز العملة المحلية للدولة (مثال: ر.س، ج.م، د.إ)
  final String country; // اسم الدولة المنشأ فيها الخدمة (مثال: السعودية، مصر)

  // Provider assignment & details
  final String? assignedProviderId;
  final String? assignedProviderName;
  final String? assignedProviderPhone;
  final String? assignedProviderProfession;
  final int? assignedProviderAge;
  final double? assignedProviderRating;

  // Rating & Completion confirmation from client
  final double? clientRating; // تقييم العميل للمغامر (1 إلى 5 نجوم)
  final String? clientReview; // رأي أو تعليق العميل
  final bool isClientConfirmed; // هل أكد العميل تمام الخدمة؟

  // Status & Timestamps
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const ServiceRequestModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    this.clientLocation,
    this.addressTitle = '',
    required this.category,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.suggestedBudget = 0.0,
    this.adminApprovedPrice,
    this.finalPrice,
    this.adminNotes = '',
    this.isModifiedByAdmin = false,
    this.currency = '',
    this.country = '',
    this.assignedProviderId,
    this.assignedProviderName,
    this.assignedProviderPhone,
    this.assignedProviderProfession,
    this.assignedProviderAge,
    this.assignedProviderRating,
    this.clientRating,
    this.clientReview,
    this.isClientConfirmed = false,
    this.status = RequestStatus.pendingAdmin,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  /// إرجاع العملة المحلية الفعلية (مع كشف تلقائي بالذكاء الجغرافي إذا كانت فارغة للطلبات القديمة)
  String get effectiveCurrency {
    if (currency.isNotEmpty) return currency;
    return CurrencyHelper.resolveCurrency(location: clientLocation, phone: clientPhone, address: addressTitle);
  }

  /// تنسيق السعر مع العملة المحلية المعتمدة للخدمة
  String formatPrice(double? price) {
    if (price == null) return 'غير محدد';
    return '${price.toStringAsFixed(0)} $effectiveCurrency';
  }

  factory ServiceRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ServiceRequestModel.fromMap(data, doc.id);
  }

  factory ServiceRequestModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ServiceRequestModel(
      id: docId ?? (map['id'] ?? ''),
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      clientLocation: map['clientLocation'] is GeoPoint ? map['clientLocation'] as GeoPoint : null,
      addressTitle: map['addressTitle'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      suggestedBudget: (map['suggestedBudget'] is num) ? (map['suggestedBudget'] as num).toDouble() : 0.0,
      adminApprovedPrice: (map['adminApprovedPrice'] is num) ? (map['adminApprovedPrice'] as num).toDouble() : null,
      finalPrice: (map['finalPrice'] is num) ? (map['finalPrice'] as num).toDouble() : null,
      adminNotes: map['adminNotes'] ?? '',
      isModifiedByAdmin: map['isModifiedByAdmin'] ?? false,
      currency: map['currency'] ?? '',
      country: map['country'] ?? '',
      assignedProviderId: map['assignedProviderId'],
      assignedProviderName: map['assignedProviderName'],
      assignedProviderPhone: map['assignedProviderPhone'],
      assignedProviderProfession: map['assignedProviderProfession'],
      assignedProviderAge: (map['assignedProviderAge'] is num) ? (map['assignedProviderAge'] as num).toInt() : null,
      assignedProviderRating: (map['assignedProviderRating'] is num) ? (map['assignedProviderRating'] as num).toDouble() : null,
      clientRating: (map['clientRating'] is num) ? (map['clientRating'] as num).toDouble() : null,
      clientReview: map['clientReview'],
      isClientConfirmed: map['isClientConfirmed'] ?? false,
      status: RequestStatusExtension.fromString(map['status']),
      createdAt: map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp ? (map['updatedAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] is Timestamp ? (map['completedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientLocation': clientLocation,
      'addressTitle': addressTitle,
      'category': category,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'suggestedBudget': suggestedBudget,
      'adminApprovedPrice': adminApprovedPrice,
      'finalPrice': finalPrice ?? adminApprovedPrice ?? suggestedBudget,
      'adminNotes': adminNotes,
      'isModifiedByAdmin': isModifiedByAdmin,
      'currency': effectiveCurrency,
      'country': country.isNotEmpty ? country : CurrencyHelper.detectCountry(location: clientLocation, phone: clientPhone, address: addressTitle).name,
      'assignedProviderId': assignedProviderId,
      'assignedProviderName': assignedProviderName,
      'assignedProviderPhone': assignedProviderPhone,
      'assignedProviderProfession': assignedProviderProfession,
      'assignedProviderAge': assignedProviderAge,
      'assignedProviderRating': assignedProviderRating,
      'clientRating': clientRating,
      'clientReview': clientReview,
      'isClientConfirmed': isClientConfirmed,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  ServiceRequestModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientPhone,
    GeoPoint? clientLocation,
    String? addressTitle,
    String? category,
    String? title,
    String? description,
    List<String>? imageUrls,
    double? suggestedBudget,
    double? adminApprovedPrice,
    double? finalPrice,
    String? adminNotes,
    bool? isModifiedByAdmin,
    String? currency,
    String? country,
    String? assignedProviderId,
    String? assignedProviderName,
    String? assignedProviderPhone,
    String? assignedProviderProfession,
    int? assignedProviderAge,
    double? assignedProviderRating,
    double? clientRating,
    String? clientReview,
    bool? isClientConfirmed,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return ServiceRequestModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientLocation: clientLocation ?? this.clientLocation,
      addressTitle: addressTitle ?? this.addressTitle,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      suggestedBudget: suggestedBudget ?? this.suggestedBudget,
      adminApprovedPrice: adminApprovedPrice ?? this.adminApprovedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      adminNotes: adminNotes ?? this.adminNotes,
      isModifiedByAdmin: isModifiedByAdmin ?? this.isModifiedByAdmin,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      assignedProviderId: assignedProviderId ?? this.assignedProviderId,
      assignedProviderName: assignedProviderName ?? this.assignedProviderName,
      assignedProviderPhone: assignedProviderPhone ?? this.assignedProviderPhone,
      assignedProviderProfession: assignedProviderProfession ?? this.assignedProviderProfession,
      assignedProviderAge: assignedProviderAge ?? this.assignedProviderAge,
      assignedProviderRating: assignedProviderRating ?? this.assignedProviderRating,
      clientRating: clientRating ?? this.clientRating,
      clientReview: clientReview ?? this.clientReview,
      isClientConfirmed: isClientConfirmed ?? this.isClientConfirmed,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
