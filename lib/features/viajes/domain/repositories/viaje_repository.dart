import '../entities/viaje.dart';
import '../entities/ubicacion_gps.dart';

abstract class ViajeRepository {
  /// Obtiene los viajes asignados al conductor
  Future<List<Viaje>> obtenerMisViajes({
    String? estado,
    DateTime? fecha,
    required String token,
  });

  /// Obtiene el viaje activo del conductor (si existe)
  Future<Viaje?> obtenerViajeActivo({required String token});

  /// Inicia un viaje
  Future<Viaje> iniciarViaje({
    required int idViaje,
    required String token,
  });

  /// Finaliza un viaje
  Future<Viaje> finalizarViaje({
    required int idViaje,
    required String token,
  });

  /// Marca llegada a un paradero
  Future<void> marcarLlegadaParadero({
    required int idViaje,
    required int idParadero,
    required String token,
  });

  /// Envía ubicación GPS al servidor
  Future<void> enviarUbicacionGPS({
    required UbicacionGPS ubicacion,
    required String token,
  });

  /// Obtiene el historial de viajes del conductor
  Future<List<Viaje>> obtenerHistorial({
    required String token,
    int page = 0,
    int size = 20,
  });
}

