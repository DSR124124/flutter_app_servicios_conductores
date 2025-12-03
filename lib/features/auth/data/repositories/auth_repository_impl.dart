import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  }) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
       _localDataSource = localDataSource ?? AuthLocalDataSource();

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthUser? _cachedUser;
  bool _hydrated = false;

  Future<void> _hydrate() async {
    if (_hydrated) return;
    _cachedUser = await _localDataSource.getCachedUser();
    _hydrated = true;
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    await _hydrate();
    return _cachedUser;
  }

  @override
  AuthUser? get cachedUser => _cachedUser;

  @override
  Future<AuthUser> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final user = await _remoteDataSource.login(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );
    _cachedUser = user;
    await _localDataSource.cacheUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    _cachedUser = null;
    await _localDataSource.clear();
  }
}

