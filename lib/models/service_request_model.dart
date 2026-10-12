import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pendingAdmin,           // بانتظار مراجعة وتسعير الإدارة
  waitingClientApproval,  // تم التسعير من الإدارة وبانتظار موافقة العميل
  published,              // معتمد ومنشور للفنيين المطابقين في المنطقة
  accepted,               // تم قبول الطلب من فني محدد
  inProgress,             // جاري تنفيذ العمل في موقع العميل
  completed,              // تم إتمام العمل وتحويل المستحقات للمحفظة
  cancelled,              // تم إلغاء الطلب
}

extension RequestStatusExtension on RequestStatus {
  String get titleAr {
    switch (this) {
      case RequestStatus.pendingAdmin:
        return 'بانتظار تسعير الإدارة';
      case RequestStatus.waitingClientApproval:
        return 'بانتظار موافقتك على التسعيرة';
      case RequestStatus.published:
        return 'متاح للفنيين القريبين';
      case RequestStatus.accepted:
        return 'تم قبول الطلب من فني';
      case RequestStatus.inProgress:
        return 'قيد التنفيذ';
      case RequestStatus.completed:
        return 'مكتمل';
      case RequestStatus.cancelled:
        return 'ملغي';
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
  final String category;          // مثل: سباكة، كهرباء، صيانة أجهزة...
  final String title;
  final String description;
  final List<String> imageUrls;

  // Pricing
  final double suggestedBudget;       // السعر المقترح من العميل
  final double? adminApprovedPrice;   // السعر المحدد/المعاد تسعيره من الإدارة
  final double? finalPrice;           // السعر النهائي المتفق عليه

  // Provider assignment & details
  final String? assignedProviderId;
  final String? assignedProviderName;
  final String? assignedProviderPhone;
  final String? assignedProviderProfession;
  final int? assignedProviderAge;
  final double? assignedProviderRating;

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
    this.assignedProviderId,
    this.assignedProviderName,
    this.assignedProviderPhone,
    this.assignedProviderProfession,
    this.assignedProviderAge,
    this.assignedProviderRating,
    this.status = RequestStatus.pendingAdmin,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

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
      assignedProviderId: map['assignedProviderId'],
      assignedProviderName: map['assignedProviderName'],
      assignedProviderPhone: map['assignedProviderPhone'],
      assignedProviderProfession: map['assignedProviderProfession'],
      assignedProviderAge: (map['assignedProviderAge'] is num) ? (map['assignedProviderAge'] as num).toInt() : null,
      assignedProviderRating: (map['assignedProviderRating'] is num) ? (map['assignedProviderRating'] as num).toDouble() : null,
      status: RequestStatusExtension.fromString(map['status']),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
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
      'assignedProviderId': assignedProviderId,
      'assignedProviderName': assignedProviderName,
      'assignedProviderPhone': assignedProviderPhone,
      'assignedProviderProfession': assignedProviderProfession,
      'assignedProviderAge': assignedProviderAge,
      'assignedProviderRating': assignedProviderRating,
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
    String? assignedProviderId,
    String? assignedProviderName,
    String? assignedProviderPhone,
    String? assignedProviderProfession,
    int? assignedProviderAge,
    double? assignedProviderRating,
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
      assignedProviderId: assignedProviderId ?? this.assignedProviderId,
      assignedProviderName: assignedProviderName ?? this.assignedProviderName,
      assignedProviderPhone: assignedProviderPhone ?? this.assignedProviderPhone,
      assignedProviderProfession: assignedProviderProfession ?? this.assignedProviderProfession,
      assignedProviderAge: assignedProviderAge ?? this.assignedProviderAge,
      assignedProviderRating: assignedProviderRating ?? this.assignedProviderRating,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
