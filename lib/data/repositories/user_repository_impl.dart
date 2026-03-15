import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class UserRepositoryImpl implements UserRepository {
  User? _cachedUser;
  bool _biometricEnabled = true;
  bool _identityMonitoring = true;

  Future<User> _loadUser() async {
    if (_cachedUser != null) return _cachedUser!;
    
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'User';
    final phone = prefs.getString('user_phone') ?? '+91 00000 00000';
    final email = prefs.getString('user_email') ?? '${name.toLowerCase().replaceAll(' ', '.')}@email.com';
    final isFrozen = prefs.getBool('account_frozen') ?? false;

    _cachedUser = User(
      id: '1',
      name: name,
      email: email,
      phoneNumber: phone,
      securityScore: 850,
      fraudPrevented: 47500.0,
      isAccountFrozen: isFrozen,
      accountBalance: 12450.00,
    );
    return _cachedUser!;
  }

  @override
  Future<User> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _loadUser();
  }

  @override
  Future<User> refreshSecurityScore() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final user = await _loadUser();
    final newScore = 840 + (DateTime.now().millisecond % 100);
    _cachedUser = user.copyWith(securityScore: newScore);
    return _cachedUser!;
  }

  @override
  Future<void> updateBiometricSetting(bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _biometricEnabled = enabled;
  }

  @override
  Future<void> updateIdentityMonitoring(bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _identityMonitoring = enabled;
  }

  @override
  Future<User> toggleAccountFreeze() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = await _loadUser();
    _cachedUser = user.copyWith(
      isAccountFrozen: !user.isAccountFrozen,
    );
    // Persist freeze state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('account_frozen', _cachedUser!.isAccountFrozen);
    return _cachedUser!;
  }

  @override
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_phone', user.phoneNumber);
    await prefs.setString('user_email', user.email);
    _cachedUser = user;
  }
}
