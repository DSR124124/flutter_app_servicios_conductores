import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/datasources/viaje_remote_data_source.dart';
import '../../data/models/viaje_model.dart';
import '../../domain/entities/estadisticas.dart';
import '../../domain/entities/llegada_paradero.dart';
import '../../domain/entities/proximo_paradero.dart';
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
  ProximoParadero? _proximoParadero;
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
  ProximoParadero? get proximoParadero => _proximoParadero;
  EstadisticasConductor? get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get posicionActual => _posicionActual;
  bool get gpsActivo => _gpsActivo;
  bool get tieneViajeActivo => _viajeActivo != null;
  
  /// Obtiene el siguiente paradero pendiente del viaje activo
  Paradero? get siguienteParadero {
    if (_viajeActivo == null) return null;
    // Primero buscar por estadoParadero == 'siguiente'
    final siguiente = _viajeActivo!.paraderos.where((p) => p.esSiguiente).firstOrNull;
    if (siguiente != null) return siguiente;
    // Si no hay marcado como siguiente, buscar el primer no visitado
    return _viajeActivo!.paraderos.where((p) => !p.estaVisitado).firstOrNull;
  }
  
  /// Indica si todos los paraderos han sido visitados
  bool get todosParaderosVisitados {
    if (_viajeActivo == null) return false;
    return _viajeActivo!.paraderos.every((p) => p.estaVisitado);
  }

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

    // Escuchar cambios de posición - optimizado para navegación en tiempo real
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualizar cada 5 metros para mayor precisión
        timeLimit: const Duration(seconds: 2), // Timeout de 2 segundos
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

    // Timer para enviar ubicación cada 2 segundos (navegación en tiempo real)
    _gpsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
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
    } catch (_) {
      // Silenciar errores de envío GPS para no molestar al usuario
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

  /// Obtiene el próximo paradero a visitar desde el backend
  Future<ProximoParadero?> obtenerProximoParadero({required String token}) async {
    if (_viajeActivo == null) {
      _error = 'No hay viaje activo';
      notifyListeners();
      return null;
    }

    try {
      _proximoParadero = await _dataSource.fetchProximoParadero(
        idViaje: _viajeActivo!.idViaje,
        token: token,
      );
      notifyListeners();
      return _proximoParadero;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _error = AppException.unknown().message;
      notifyListeners();
      return null;
    }
  }

  /// Marca la llegada a un paradero durante el viaje activo.
  /// El backend valida que los paraderos se marquen en orden secuencial.
  Future<LlegadaParaderoResponse?> marcarLlegadaParadero({
    required int idParadero,
    required String token,
  }) async {
    if (_viajeActivo == null) {
      _error = 'No hay viaje activo';
      notifyListeners();
      return null;
    }

    try {
      // Usar coordenadas actuales si están disponibles
      final response = await _dataSource.marcarLlegadaParadero(
        idViaje: _viajeActivo!.idViaje,
        idParadero: idParadero,
        token: token,
        latitud: _posicionActual?.latitude,
        longitud: _posicionActual?.longitude,
      );

      // Actualizar el paradero como visitado y marcar el siguiente
      _actualizarEstadosParaderos(idParadero, response);

      notifyListeners();
      return response;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _error = AppException.unknown().message;
      notifyListeners();
      return null;
    }
  }

  /// Actualiza los estados de los paraderos después de marcar llegada
  void _actualizarEstadosParaderos(int idParaderoVisitado, LlegadaParaderoResponse response) {
    if (_viajeActivo == null) return;

    final paraderos = _viajeActivo!.paraderos;
    final siguienteOrden = response.ordenParadero + 1;
    
    // Crear lista actualizada de paraderos con nuevos estados
    final paraderosActualizados = paraderos.map((p) {
      String nuevoEstado;
      bool nuevoVisitado = p.visitado;
      DateTime? nuevaHoraLlegada = p.horaLlegadaReal;
      
      if (p.idParadero == idParaderoVisitado) {
        // Este paradero fue visitado
        nuevoEstado = 'visitado';
        nuevoVisitado = true;
        nuevaHoraLlegada = response.fechaLlegada;
      } else if (p.orden == siguienteOrden && !response.esUltimoParadero) {
        // Este es el siguiente paradero
        nuevoEstado = 'siguiente';
      } else if (p.orden < response.ordenParadero || p.visitado) {
        // Ya fue visitado anteriormente
        nuevoEstado = 'visitado';
        nuevoVisitado = true;
      } else {
        // Todavía pendiente
        nuevoEstado = 'pendiente';
      }
      
        return Paradero(
          idParadero: p.idParadero,
          nombre: p.nombre,
          latitud: p.latitud,
          longitud: p.longitud,
          orden: p.orden,
          horaLlegadaEstimada: p.horaLlegadaEstimada,
        horaLlegadaReal: nuevaHoraLlegada,
        visitado: nuevoVisitado,
        estadoParadero: nuevoEstado,
        );
    }).toList();

    // Crear nuevo viaje con paraderos actualizados
    _viajeActivo = Viaje(
      idViaje: _viajeActivo!.idViaje,
      idRuta: _viajeActivo!.idRuta,
      nombreRuta: _viajeActivo!.nombreRuta,
      idBus: _viajeActivo!.idBus,
      placaBus: _viajeActivo!.placaBus,
      modeloBus: _viajeActivo!.modeloBus,
      fechaInicioProgramada: _viajeActivo!.fechaInicioProgramada,
      fechaFinProgramada: _viajeActivo!.fechaFinProgramada,
      fechaInicioReal: _viajeActivo!.fechaInicioReal,
      fechaFinReal: _viajeActivo!.fechaFinReal,
      estado: _viajeActivo!.estado,
      paraderos: paraderosActualizados,
    );
    
    // Actualizar el próximo paradero
    if (response.esUltimoParadero) {
      _proximoParadero = ProximoParadero(
        idViaje: _viajeActivo!.idViaje,
        paraderosVisitados: response.paraderosVisitados,
        totalParaderos: response.totalParaderos,
        todosVisitados: true,
        mensaje: 'Todos los paraderos visitados. Puedes finalizar el viaje.',
      );
    } else {
      // Buscar el siguiente paradero en la lista actualizada
      final siguiente = paraderosActualizados.where((p) => p.estadoParadero == 'siguiente').firstOrNull;
      if (siguiente != null) {
        _proximoParadero = ProximoParadero(
          idViaje: _viajeActivo!.idViaje,
          idParadero: siguiente.idParadero,
          ordenParadero: siguiente.orden,
          nombreParadero: siguiente.nombre,
          latitud: siguiente.latitud,
          longitud: siguiente.longitud,
          paraderosVisitados: response.paraderosVisitados,
          totalParaderos: response.totalParaderos,
          todosVisitados: false,
          mensaje: 'Siguiente paradero en la ruta.',
        );
      }
    }
  }

  @override
  void dispose() {
    _detenerGPS();
    super.dispose();
  }
}

