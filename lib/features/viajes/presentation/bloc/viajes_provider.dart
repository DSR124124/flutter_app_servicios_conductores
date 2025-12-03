import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/datasources/viaje_remote_data_source.dart';
import '../../domain/entities/estadisticas.dart';
import '../../domain/entities/viaje.dart';
import '../../domain/entities/ubicacion_gps.dart';
import '../../domain/usecases/get_mis_viajes_usecase.dart';
import '../../domain/usecases/get_viaje_activo_usecase.dart';
import '../../domain/usecases/iniciar_viaje_usecase.dart';
import '../../domain/usecases/finalizar_viaje_usecase.dart';
import '../../domain/usecases/enviar_ubicacion_usecase.dart';

class ViajesProvider extends ChangeNotifier {
  ViajesProvider({
    required GetMisViajesUseCase getMisViajesUseCase,
    required GetViajeActivoUseCase getViajeActivoUseCase,
    required IniciarViajeUseCase iniciarViajeUseCase,
    required FinalizarViajeUseCase finalizarViajeUseCase,
    required EnviarUbicacionUseCase enviarUbicacionUseCase,
  })  : _getMisViajesUseCase = getMisViajesUseCase,
        _getViajeActivoUseCase = getViajeActivoUseCase,
        _iniciarViajeUseCase = iniciarViajeUseCase,
        _finalizarViajeUseCase = finalizarViajeUseCase,
        _enviarUbicacionUseCase = enviarUbicacionUseCase;

  final GetMisViajesUseCase _getMisViajesUseCase;
  final GetViajeActivoUseCase _getViajeActivoUseCase;
  final IniciarViajeUseCase _iniciarViajeUseCase;
  final FinalizarViajeUseCase _finalizarViajeUseCase;
  final EnviarUbicacionUseCase _enviarUbicacionUseCase;

  // Estado
  List<Viaje> _viajes = [];
  List<Viaje> _historial = [];
  Viaje? _viajeActivo;
  EstadisticasConductor? _estadisticas;
  bool _isLoading = false;
  String? _error;
  Position? _posicionActual;
  Timer? _gpsTimer;
  StreamSubscription<Position>? _positionSubscription;
  bool _gpsActivo = false;
  
  // Data source para historial y estadísticas
  final ViajeRemoteDataSource _dataSource = ViajeRemoteDataSource();

  // Getters
  List<Viaje> get viajes => _viajes;
  List<Viaje> get viajesProgramados => _viajes.where((v) => v.esProgramado).toList();
  List<Viaje> get historial => _historial;
  Viaje? get viajeActivo => _viajeActivo;
  EstadisticasConductor? get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get posicionActual => _posicionActual;
  bool get gpsActivo => _gpsActivo;
  bool get tieneViajeActivo => _viajeActivo != null;

  /// Carga los viajes del conductor
  Future<void> cargarViajes({required String token, DateTime? fecha}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _viajes = await _getMisViajesUseCase(token: token, fecha: fecha);
      _viajeActivo = await _getViajeActivoUseCase(token: token);
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = AppException.unknown().message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia un viaje
  Future<bool> iniciarViaje({
    required int idViaje,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _viajeActivo = await _iniciarViajeUseCase(idViaje: idViaje, token: token);
      
      // Actualizar lista de viajes
      final index = _viajes.indexWhere((v) => v.idViaje == idViaje);
      if (index != -1) {
        _viajes = List.from(_viajes)..[index] = _viajeActivo!;
      }

      // Iniciar envío de GPS
      await _iniciarGPS(token);

      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = AppException.unknown().message;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Finaliza el viaje activo
  Future<bool> finalizarViaje({required String token}) async {
    if (_viajeActivo == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final viajeTerminado = await _finalizarViajeUseCase(
        idViaje: _viajeActivo!.idViaje,
        token: token,
      );
      
      // Detener GPS
      _detenerGPS();

      // Actualizar lista de viajes
      final index = _viajes.indexWhere((v) => v.idViaje == _viajeActivo!.idViaje);
      if (index != -1) {
        _viajes = List.from(_viajes)..[index] = viajeTerminado;
      }

      _viajeActivo = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = AppException.unknown().message;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia el tracking GPS
  Future<void> _iniciarGPS(String token) async {
    // Verificar permisos
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        _error = 'Se requieren permisos de ubicación';
        notifyListeners();
        return;
      }
    }

    // Verificar que el servicio esté habilitado
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'El servicio de ubicación está deshabilitado';
      notifyListeners();
      return;
    }

    _gpsActivo = true;

    // Escuchar cambios de posición
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
      ),
    ).listen(
      (position) {
        _posicionActual = position;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Error al obtener ubicación: $error';
        notifyListeners();
      },
    );

    // Timer para enviar ubicación cada 10 segundos
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_viajeActivo != null && _posicionActual != null) {
        await _enviarUbicacion(token);
      }
    });

    notifyListeners();
  }

  /// Detiene el tracking GPS
  void _detenerGPS() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _gpsActivo = false;
    notifyListeners();
  }

  /// Envía la ubicación actual al servidor
  Future<void> _enviarUbicacion(String token) async {
    if (_viajeActivo == null || _posicionActual == null) return;

    try {
      final ubicacion = UbicacionGPS(
        idViaje: _viajeActivo!.idViaje,
        latitud: _posicionActual!.latitude,
        longitud: _posicionActual!.longitude,
        velocidadKmh: _posicionActual!.speed * 3.6, // m/s a km/h
        rumbo: _posicionActual!.heading,
        timestamp: DateTime.now(),
      );

      await _enviarUbicacionUseCase(ubicacion: ubicacion, token: token);
    } catch (e) {
      // Silenciar errores de envío GPS para no molestar al usuario
      debugPrint('Error enviando GPS: $e');
    }
  }

  /// Envía ubicación manualmente (para testing)
  Future<void> enviarUbicacionManual({required String token}) async {
    if (_viajeActivo == null) return;
    
    try {
      _posicionActual = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _enviarUbicacion(token);
      notifyListeners();
    } catch (e) {
      _error = 'Error al obtener ubicación: $e';
      notifyListeners();
    }
  }

  /// Inicia el GPS si hay un viaje activo (para cuando se abre la página directamente)
  Future<void> iniciarGPSSiHayViajeActivo({required String token}) async {
    if (_viajeActivo == null) return;
    if (_gpsActivo) return; // Ya está corriendo
    
    await _iniciarGPS(token);
  }

  /// Obtiene la posición actual una sola vez (para inicialización)
  Future<Position?> obtenerPosicionActual() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      // Verificar que el servicio esté habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Obtener posición
      _posicionActual = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      notifyListeners();
      return _posicionActual;
    } catch (_) {
      return null;
    }
  }

  /// Carga el historial de viajes finalizados
  Future<int> cargarHistorial({
    required String token,
    int page = 0,
    bool append = false,
  }) async {
    if (!append) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final nuevosViajes = await _dataSource.fetchHistorial(
        token: token,
        page: page,
      );
      
      if (append) {
        _historial = [..._historial, ...nuevosViajes];
      } else {
        _historial = nuevosViajes;
      }
      
      notifyListeners();
      return nuevosViajes.length;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return 0;
    } catch (_) {
      _error = AppException.unknown().message;
      notifyListeners();
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las estadísticas del conductor
  Future<void> cargarEstadisticas({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _estadisticas = await _dataSource.fetchEstadisticas(token: token);
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = AppException.unknown().message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _detenerGPS();
    super.dispose();
  }
}

