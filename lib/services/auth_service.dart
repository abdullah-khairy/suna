import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/local_storage_service.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('user');

  /// تسجيل دخول مجاني 100% برقم الهاتف وكلمة المرور بدون أي رسائل SMS مدفوعة
  Future<UserModel?> loginWithPhone({required String phone, required String password}) async {
    try {
      final query = await _usersCollection.where('phone', isEqualTo: phone.trim()).limit(1).get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      final user = UserModel.fromFirestore(doc);

      if (user.password.isNotEmpty && user.password != password.trim()) {
        return null;
      }

      await LocalStorageService.saveUserSession(userId: user.id, role: user.role, phone: user.phone, name: user.name);
      return user;
    } catch (_) {}
    return null;
  }

  /// تسجيل حساب صنايعي / مهني جديد في ثوانٍ مع الموافقة عليه
  Future<UserModel> registerCraftsman({required String name, required String phone, required String profession, required int age, required String password, GeoPoint? location}) async {
    final existing = await _usersCollection.where('phone', isEqualTo: phone.trim()).limit(1).get();

    final docRef = existing.docs.isNotEmpty ? _usersCollection.doc(existing.docs.first.id) : _usersCollection.doc();

    final newUser = UserModel(
      id: docRef.id,
      name: name.trim(),
      phone: phone.trim(),
      password: password.trim(),
      age: age,
      role: UserRole.provider,
      profession: profession.trim(),
      description: 'فني متخصص في $profession مستعد لتقديم أفضل خدمة',
      location: location,
      isAvailable: true,
      isApproved: true,
      createdAt: DateTime.now(),
    );

    await docRef.set(newUser.toMap(), SetOptions(merge: true));

    await LocalStorageService.saveUserSession(userId: newUser.id, role: newUser.role, phone: newUser.phone, name: newUser.name);

    return newUser;
  }

  /// زرع حساب مسؤول تجريبي افتراضي في حال لم يكن موجوداً
  Future<void> seedAdminAccountIfMissing() async {
    try {
      final check = await _usersCollection.where('phone', isEqualTo: '0500000000').limit(1).get();
      if (check.docs.isEmpty) {
        final docRef = _usersCollection.doc('admin_master_1');
        final admin = UserModel(
          id: docRef.id,
          name: 'مدير النظام',
          phone: '0500000000',
          password: 'admin',
          age: 35,
          role: UserRole.admin,
          profession: 'إدارة',
          description: 'مسؤول مراجعة واعتماد الطلبات والتسعير',
          createdAt: DateTime.now(),
        );
        await docRef.set(admin.toMap());
      }
    } catch (_) {}
  }

  /// تسجيل خروج
  Future<void> logout() async {
    await LocalStorageService.clearSession();
  }

  /// استرجاع بيانات المستخدم الحالي المسجل
  Future<UserModel?> getCurrentUser() async {
    final userId = LocalStorageService.getUserId();
    if (userId == null || userId.isEmpty) return null;

    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }
}
