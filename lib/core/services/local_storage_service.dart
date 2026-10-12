import 'package:get_storage/get_storage.dart';
import '../../models/user_model.dart';

class LocalStorageService {
  static final GetStorage _box = GetStorage();

  static const String _keyUserId = 'current_user_id';
  static const String _keyUserRole = 'current_user_role';
  static const String _keyUserPhone = 'current_user_phone';
  static const String _keyUserName = 'current_user_name';

  static Future<void> saveUserSession({
    required String userId,
    required UserRole role,
    String? phone,
    String? name,
  }) async {
    await _box.write(_keyUserId, userId);
    await _box.write(_keyUserRole, role.name);
    if (phone != null) await _box.write(_keyUserPhone, phone);
    if (name != null) await _box.write(_keyUserName, name);
  }

  static String? getUserId() => _box.read<String>(_keyUserId);

  static UserRole getUserRole() {
    final roleStr = _box.read<String>(_keyUserRole);
    return UserRoleExtension.fromString(roleStr);
  }

  static String? getUserPhone() => _box.read<String>(_keyUserPhone);
  static String? getUserName() => _box.read<String>(_keyUserName);

  static Future<void> clearSession() async {
    await _box.remove(_keyUserId);
    await _box.remove(_keyUserRole);
    await _box.remove(_keyUserPhone);
    await _box.remove(_keyUserName);
  }
}
