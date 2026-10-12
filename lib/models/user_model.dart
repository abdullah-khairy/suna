import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  client,    // عميل يطلب الخدمات
  provider,  // فني / مهني يقدم الخدمات
  admin,     // مسؤول النظام
}

extension UserRoleExtension on UserRole {
  String get nameAr {
    switch (this) {
      case UserRole.client:
        return 'عميل';
      case UserRole.provider:
        return 'مقدم خدمة';
      case UserRole.admin:
        return 'مسؤول';
    }
  }

  static UserRole fromString(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'provider':
      case 'worker':
      case 'مهني':
      case 'فني':
        return UserRole.provider;
      case 'admin':
      case 'مسؤول':
        return UserRole.admin;
      default:
        return UserRole.client;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String password;         // كلمة المرور للدخول بدون تكاليف SMS
  final int age;                 // العمر
  final UserRole role;
  final String profession;       // التخصص/المهنة (سباك، كهربائي، إلخ)
  final String description;      // نبذة أو وصف
  final GeoPoint? location;      // إحداثيات الموقع
  final double rating;           // متوسط التقييم (1.0 - 5.0)
  final int completedTasksCount; // عدد الخدمات المكتملة
  final double walletBalance;    // رصيد المحفظة الحالي
  final bool isAvailable;        // هل هو متاح لاستقبال طلبات حالياً؟
  final bool isApproved;         // هل تمت الموافقة على حسابه من الإدارة؟
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.password = '',
    this.age = 25,
    this.role = UserRole.client,
    this.profession = '',
    this.description = '',
    this.location,
    this.rating = 5.0,
    this.completedTasksCount = 0,
    this.walletBalance = 0.0,
    this.isAvailable = true,
    this.isApproved = true, // مفعل افتراضياً لتسهيل التجربة
    required this.createdAt,
  });

  bool get isProvider => role == UserRole.provider;
  bool get isClient => role == UserRole.client;
  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      id: docId ?? (map['id'] ?? ''),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      password: map['password'] ?? '',
      age: (map['age'] is num) ? (map['age'] as num).toInt() : 25,
      role: UserRoleExtension.fromString(map['role']),
      profession: map['profession'] ?? map['jop'] ?? '',
      description: map['description'] ?? map['discription'] ?? '',
      location: map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 5.0,
      completedTasksCount: (map['completedTasksCount'] is num) ? (map['completedTasksCount'] as num).toInt() : 0,
      walletBalance: (map['walletBalance'] is num) ? (map['walletBalance'] as num).toDouble() : 0.0,
      isAvailable: map['isAvailable'] ?? true,
      isApproved: map['isApproved'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'password': password,
      'age': age,
      'role': role.name,
      'profession': profession,
      'jop': profession,
      'description': description,
      'discription': description,
      'location': location,
      'rating': rating,
      'completedTasksCount': completedTasksCount,
      'walletBalance': walletBalance,
      'isAvailable': isAvailable,
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? password,
    int? age,
    UserRole? role,
    String? profession,
    String? description,
    GeoPoint? location,
    double? rating,
    int? completedTasksCount,
    double? walletBalance,
    bool? isAvailable,
    bool? isApproved,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      age: age ?? this.age,
      role: role ?? this.role,
      profession: profession ?? this.profession,
      description: description ?? this.description,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      walletBalance: walletBalance ?? this.walletBalance,
      isAvailable: isAvailable ?? this.isAvailable,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
