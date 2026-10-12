import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String name;             // اسم المحل أو المورد (مثال: البركة للحدايد والبويات)
  final String ownerName;        // اسم المسؤول / صاحب المحل
  final String phone;            // رقم الهاتف للتواصل والطلبات
  final String category;         // القسم (رمل وأسمنت، حدايد وبويات، أدوات صحية، كهرباء...)
  final String description;      // وصف المنتجات المتوفرة
  final String addressTitle;     // العنوان المكتوب / المنطقة
  final GeoPoint? location;      // الإحداثيات لحساب المسافة والملاحة
  final bool deliveryAvailable;  // هل يوفر خدمة توصيل المون للموقع؟
  final double rating;           // التقييم
  final DateTime createdAt;

  const SupplierModel({
    required this.id,
    required this.name,
    this.ownerName = '',
    required this.phone,
    required this.category,
    required this.description,
    this.addressTitle = '',
    this.location,
    this.deliveryAvailable = true,
    this.rating = 5.0,
    required this.createdAt,
  });

  factory SupplierModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return SupplierModel.fromMap(data, doc.id);
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return SupplierModel(
      id: docId ?? (map['id'] ?? ''),
      name: map['name'] ?? '',
      ownerName: map['ownerName'] ?? '',
      phone: map['phone'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      addressTitle: map['addressTitle'] ?? '',
      location: map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
      deliveryAvailable: map['deliveryAvailable'] ?? true,
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 5.0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'category': category,
      'description': description,
      'addressTitle': addressTitle,
      'location': location,
      'deliveryAvailable': deliveryAvailable,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? phone,
    String? category,
    String? description,
    String? addressTitle,
    GeoPoint? location,
    bool? deliveryAvailable,
    double? rating,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      description: description ?? this.description,
      addressTitle: addressTitle ?? this.addressTitle,
      location: location ?? this.location,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> categories = [
    'رمل وأسمنت ومواد بناء',
    'حدايد وبويات',
    'أدوات صحية وسباكة',
    'أدوات وكابلات كهربائية',
    'أخشاب ومستلزمات نجارة',
    'تكييف وتبريد وقطع غيار',
    'معدات وعِدد يدوية',
  ];
}
