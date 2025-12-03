import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String usernameOrEmail,
    required String password,
  }) {
    return _repository.login(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );
  }
}

