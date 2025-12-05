import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'directions_service.dart';

/// Servicio de navegación en tiempo real
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _updateTimer;
  
  NavigationResponse? _currentRoute;
  List<LatLng> _routePoints = [];
  List<NavigationInstruction> _instructions = [];
  int _currentInstructionIndex = 0;
  
  Position? _currentPosition;
  DateTime? _lastRecalculationTime;
  
  final _positionController = StreamController<Position>.broadcast();
  final _instructionController = StreamController<NavigationInstruction?>.broadcast();
  final _routeController = StreamController<List<LatLng>>.broadcast();
  
  // Configuración
  static const double _deviationThreshold = 50.0; // metros
  static const Duration _updateInterval = Duration(seconds: 2);
  static const Duration _recalculationCooldown = Duration(seconds: 30);
  
  // Getters
  Stream<Position> get positionStream => _positionController.stream;
  Stream<NavigationInstruction?> get instructionStream => _instructionController.stream;
  Stream<List<LatLng>> get routeStream => _routeController.stream;
  
  NavigationResponse? get currentRoute => _currentRoute;
  NavigationInstruction? get currentInstruction => 
      _currentInstructionIndex < _instructions.length 
          ? _instructions[_currentInstructionIndex] 
          : null;
  Position? get currentPosition => _currentPosition;
  bool get isNavigating => _positionSubscription != null;

  /// Inicia la navegación con una ruta
  Future<void> startNavigation(NavigationResponse route) async {
    _currentRoute = route;
    _routePoints = route.route;
    _instructions = route.instructions;
    _currentInstructionIndex = 0;
    _lastRecalculationTime = null;
    
    _routeController.add(_routePoints);
    if (_instructions.isNotEmpty) {
      _instructionController.add(_instructions[0]);
    }
    
    // Verificar permisos
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied || 
          requested == LocationPermission.deniedForever) {
        throw Exception('Se requieren permisos de ubicación');
      }
    }
    
    // Iniciar seguimiento de posición
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualizar cada 5 metros
      ),
    ).listen(
      (position) {
        _currentPosition = position;
        _positionController.add(position);
        _checkDeviation(position);
        _updateCurrentInstruction(position);
      },
      onError: (error) {
        print('[NAVIGATION] Error en GPS: $error');
      },
    );
    
    // Timer para actualizaciones periódicas
    _updateTimer = Timer.periodic(_updateInterval, (_) {
      if (_currentPosition != null) {
        _checkDeviation(_currentPosition!);
        _updateCurrentInstruction(_currentPosition!);
      }
    });
    
    print('[NAVIGATION] Navegación iniciada - ${_instructions.length} instrucciones');
  }

  /// Detiene la navegación
  void stopNavigation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    
    _currentRoute = null;
    _routePoints = [];
    _instructions = [];
    _currentInstructionIndex = 0;
    _currentPosition = null;
    _lastRecalculationTime = null;
    
    print('[NAVIGATION] Navegación detenida');
  }

  /// Verifica si el vehículo se ha desviado de la ruta
  void _checkDeviation(Position position) {
    if (_routePoints.isEmpty || _currentRoute == null) return;
    
    final currentPoint = LatLng(position.latitude, position.longitude);
    final distanceToRoute = DirectionsService.distanceToRoute(currentPoint, _routePoints);
    
    if (distanceToRoute > _deviationThreshold) {
      // Verificar cooldown para evitar recálculos excesivos
      if (_lastRecalculationTime != null) {
        final timeSinceLastRecalc = DateTime.now().difference(_lastRecalculationTime!);
        if (timeSinceLastRecalc < _recalculationCooldown) {
          return;
        }
      }
      
      print('[NAVIGATION] Desviación detectada: ${distanceToRoute.toStringAsFixed(1)}m - Recalculando ruta...');
      _recalculateRoute(position);
    }
  }

  /// Recalcula la ruta desde la posición actual
  Future<void> _recalculateRoute(Position position) async {
    if (_currentRoute == null || _routePoints.isEmpty) return;
    
    try {
      final currentPoint = LatLng(position.latitude, position.longitude);
      final destination = _routePoints.last;
      
      // Recalcular desde posición actual hasta destino
      final newRoute = await DirectionsService.getNavigationRoute([
        currentPoint,
        destination,
      ]);
      
      if (newRoute != null && newRoute.route.isNotEmpty) {
        _currentRoute = newRoute;
        _routePoints = newRoute.route;
        _instructions = newRoute.instructions;
        _currentInstructionIndex = 0;
        _lastRecalculationTime = DateTime.now();
        
        _routeController.add(_routePoints);
        if (_instructions.isNotEmpty) {
          _instructionController.add(_instructions[0]);
        }
        
        print('[NAVIGATION] Ruta recalculada - ${_instructions.length} nuevas instrucciones');
      }
    } catch (e) {
      print('[NAVIGATION] Error al recalcular ruta: $e');
    }
  }

  /// Actualiza la instrucción actual basada en la posición
  void _updateCurrentInstruction(Position position) {
    if (_instructions.isEmpty || _currentRoute == null) return;
    
    // Buscar la instrucción más cercana
    int closestIndex = _currentInstructionIndex;
    double minDistance = double.infinity;
    
    for (int i = _currentInstructionIndex; i < _instructions.length; i++) {
      final instruction = _instructions[i];
      if (instruction.location == null) continue;
      
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        instruction.location!.latitude,
        instruction.location!.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    // Si estamos a menos de 30 metros de la siguiente instrucción, avanzar
    if (closestIndex > _currentInstructionIndex && minDistance < 30) {
      _currentInstructionIndex = closestIndex;
      _instructionController.add(_instructions[_currentInstructionIndex]);
      print('[NAVIGATION] Nueva instrucción: ${_instructions[_currentInstructionIndex].instruction}');
    }
  }

  /// Libera recursos
  void dispose() {
    stopNavigation();
    _positionController.close();
    _instructionController.close();
    _routeController.close();
  }
}
