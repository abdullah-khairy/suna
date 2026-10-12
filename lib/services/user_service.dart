import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/local_storage_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('user');

  /// جلب المستخدم بواسطة المعرف
  Future<UserModel?> getUserById(String id) async {
    try {
      final doc = await _usersCollection.doc(id).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      // إرجاع null عند الفشل
    }
    return null;
  }

  /// جلب المستخدم بواسطة رقم الهاتف
  Future<UserModel?> getUserByPhone(String phone) async {
    try {
      final query = await _usersCollection
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
    } catch (e) {
      // إرجاع null
    }
    return null;
  }

  /// حفظ أو تحديث بيانات المستخدم
  Future<UserModel> saveUser(UserModel user) async {
    final docRef = user.id.isEmpty
        ? _usersCollection.doc()
        : _usersCollection.doc(user.id);

    final updatedUser = user.id.isEmpty ? user.copyWith(id: docRef.id) : user;

    await docRef.set(updatedUser.toMap(), SetOptions(merge: true));

    // حفظ الجلسة محلياً
    await LocalStorageService.saveUserSession(
      userId: updatedUser.id,
      role: updatedUser.role,
      phone: updatedUser.phone,
      name: updatedUser.name,
    );

    return updatedUser;
  }

  /// تحديث الموقع الجغرافي للمستخدم
  Future<void> updateLocation(String userId, GeoPoint location) async {
    try {
      await _usersCollection.doc(userId).update({'location': location});
    } catch (_) {}
  }

  /// تبديل حالة توفر الفني (متاح / غير متاح)
  Future<void> setAvailability(String userId, bool isAvailable) async {
    try {
      await _usersCollection.doc(userId).update({'isAvailable': isAvailable});
    } catch (_) {}
  }

  /// تعديل رصيد المحفظة
  Future<void> updateWalletBalance(String userId, double newBalance) async {
    try {
      await _usersCollection.doc(userId).update({'walletBalance': newBalance});
    } catch (_) {}
  }
}
