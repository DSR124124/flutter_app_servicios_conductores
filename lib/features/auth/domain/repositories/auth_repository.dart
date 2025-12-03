import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({
    required String usernameOrEmail,
    required String password,
  });

  Future<void> logout();

  Future<AuthUser?> getCurrentUser();

  AuthUser? get cachedUser;
}

