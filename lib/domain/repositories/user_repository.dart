import '../entities/entities.dart';

abstract class UserRepository {
  Future<User> getCurrentUser();
  Future<User> refreshSecurityScore();
  Future<void> updateBiometricSetting(bool enabled);
  Future<void> updateIdentityMonitoring(bool enabled);
  Future<User> toggleAccountFreeze();
  Future<void> saveUser(User user);
}
