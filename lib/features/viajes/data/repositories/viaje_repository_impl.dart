import '../../domain/entities/viaje.dart';
import '../../domain/entities/ubicacion_gps.dart';
import '../../domain/repositories/viaje_repository.dart';
import '../datasources/viaje_remote_data_source.dart';

class ViajeRepositoryImpl implements ViajeRepository {
  ViajeRepositoryImpl({
    ViajeRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? ViajeRemoteDataSource();

  final ViajeRemoteDataSource _remoteDataSource;

  @override
  Future<List<Viaje>> obtenerMisViajes({
    String? estado,
    DateTime? fecha,
    required String token,
  }) {
    return _remoteDataSource.fetchMisViajes(
      estado: estado,
      fecha: fecha,
      token: token,
    );
  }

  @override
  Future<Viaje?> obtenerViajeActivo({required String token}) {
    return _remoteDataSource.fetchViajeActivo(token: token);
  }

  @override
  Future<Viaje> iniciarViaje({
    required int idViaje,
    required String token,
  }) {
    return _remoteDataSource.iniciarViaje(
      idViaje: idViaje,
      token: token,
    );
  }

  @override
  Future<Viaje> finalizarViaje({
    required int idViaje,
    required String token,
  }) {
    return _remoteDataSource.finalizarViaje(
      idViaje: idViaje,
      token: token,
    );
  }

  @override
  Future<void> marcarLlegadaParadero({
    required int idViaje,
    required int idParadero,
    required String token,
  }) {
    return _remoteDataSource.marcarLlegadaParadero(
      idViaje: idViaje,
      idParadero: idParadero,
      token: token,
    );
  }

  @override
  Future<void> enviarUbicacionGPS({
    required UbicacionGPS ubicacion,
    required String token,
  }) {
    return _remoteDataSource.enviarUbicacionGPS(
      ubicacion: ubicacion,
      token: token,
    );
  }

  @override
  Future<List<Viaje>> obtenerHistorial({
    required String token,
    int page = 0,
    int size = 20,
  }) {
    return _remoteDataSource.fetchHistorial(
      token: token,
      page: page,
      size: size,
    );
  }
}

