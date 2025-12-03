import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/perfil_info.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../datasources/perfil_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';

class PerfilRepositoryImpl implements PerfilRepository {
  PerfilRepositoryImpl({
    required AuthRepository authRepository,
    PerfilRemoteDataSource? remoteDataSource,
  }) : _authRepository = authRepository,
       _remoteDataSource = remoteDataSource ?? PerfilRemoteDataSource();

  final AuthRepository _authRepository;
  final PerfilRemoteDataSource _remoteDataSource;

  @override
  Future<PerfilInfo> obtenerPerfil() async {
    final user = await _authRepository.getCurrentUser();
    final token = user?.token;

    if (token == null || token.isEmpty) {
      throw AppException.sessionExpired();
    }

    final data = await _remoteDataSource.fetchPerfil(token: token);
    
    final combinedData = Map<String, dynamic>.from(data);
    
    if (user != null) {
      if ((combinedData['email'] == null || combinedData['email'] == '') && user.email != null) {
        combinedData['email'] = user.email;
      }
      if ((combinedData['nombreCompleto'] == null || combinedData['nombreCompleto'] == '') && user.nombreCompleto != null) {
        combinedData['nombreCompleto'] = user.nombreCompleto;
      }
      if ((combinedData['fechaUltimoAcceso'] == null || combinedData['fechaUltimoAcceso'] == '') && user.fechaUltimoAcceso != null) {
        combinedData['fechaUltimoAcceso'] = user.fechaUltimoAcceso;
      }
      if ((combinedData['idRol'] == null || combinedData['idRol'] == 0) && user.idRol != null) {
        combinedData['idRol'] = user.idRol;
      }
      if ((combinedData['nombreRol'] == null || combinedData['nombreRol'] == '') && user.nombreRol != null) {
        combinedData['nombreRol'] = user.nombreRol;
      }
    }
    
    return PerfilInfo.fromMap(combinedData);
  }
}

