import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

/// كلاس Usercon القديم - تم تحسينه وإصلاح مشاكله لضمان التوافق مع الكود السابق
class Usercon {
  String? id;
  String? name;
  String? phone;
  String? jop;
  String? discription;
  GeoPoint? location;
  final storgUser = GetStorage();

  Usercon({
    this.id,
    this.name,
    this.phone,
    this.jop,
    this.discription,
    this.location,
  });

  // تحويل البيانات القادمة من Firestore إلى Object
  factory Usercon.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Usercon(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      jop: data['jop'] ?? data['profession'] ?? '',
      discription: data['discription'] ?? data['description'] ?? '',
      location: data['location'] is GeoPoint ? data['location'] : null,
    );
  }

  // إنشاء كائن من UserModel الجديد
  factory Usercon.fromUserModel(UserModel user) {
    return Usercon(
      id: user.id,
      name: user.name,
      phone: user.phone,
      jop: user.profession,
      discription: user.description,
      location: user.location,
    );
  }

  // تحويل كائن Usercon إلى UserModel الحديث
  UserModel toUserModel({UserRole role = UserRole.client}) {
    return UserModel(
      id: id ?? '',
      name: name ?? '',
      phone: phone ?? '',
      role: role,
      profession: jop ?? '',
      description: discription ?? '',
      location: location,
      createdAt: DateTime.now(),
    );
  }

  // جلب بيانات المستخدم بناءً على رقم الهاتف
  static Future<Usercon?> fetchByPhone(String userPhone) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('phone', isEqualTo: userPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Usercon.fromFirestore(querySnapshot.docs.first);
      }
    } catch (_) {}
    return null;
  }

  // دالة متوافقة مع الاستدعاء القديم
  Future<Usercon?> getUsercon(String userPhone) async {
    return fetchByPhone(userPhone);
  }

  // حفظ بيانات مستخدم جديد
  Future<void> saveUsercon() async {
    try {
      DocumentReference docRef = id != null && id!.isNotEmpty
          ? FirebaseFirestore.instance.collection('user').doc(id)
          : FirebaseFirestore.instance.collection('user').doc();

      String newUserId = docRef.id;

      await docRef.set({
        'name': name,
        'phone': phone,
        'jop': jop,
        'profession': jop,
        'discription': discription,
        'description': discription,
        'location': location,
      }, SetOptions(merge: true));

      saveUserId(newUserId);
      id = newUserId;
    } catch (_) {}
  }

  void saveUserId(String id) {
    storgUser.write('user_id', id);
  }

  String? getUserId() {
    return storgUser.read<String>('user_id');
  }
}