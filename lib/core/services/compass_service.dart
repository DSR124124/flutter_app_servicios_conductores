import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';

/// Servicio singleton para manejar la brújula del dispositivo
class CompassService {
  static final CompassService _instance = CompassService._internal();
  factory CompassService() => _instance;
  CompassService._internal();

  StreamSubscription<CompassEvent>? _subscription;
  double _currentHeading = 0;
  DateTime _lastUpdate = DateTime.now();
  
  final _headingController = StreamController<double>.broadcast();
  
  /// Stream de cambios de heading
  Stream<double> get headingStream => _headingController.stream;
  
  /// Heading actual
  double get currentHeading => _currentHeading;
  
  /// Indica si la brújula está activa
  bool get isActive => _subscription != null;

  /// Inicia la escucha de la brújula
  void start({
    int minIntervalMs = 100,
    double minHeadingChange = 5.0,
  }) {
    if (_subscription != null) {
      print('[COMPASS_SERVICE] Ya está activo, ignorando start()');
      return;
    }
    
    print('[COMPASS_SERVICE] Iniciando servicio de brújula (minInterval: ${minIntervalMs}ms, minChange: ${minHeadingChange}°)');
    
    if (FlutterCompass.events == null) {
      print('[COMPASS_SERVICE] ERROR: FlutterCompass.events es null - el dispositivo no soporta brújula');
      return;
    }
    
    _subscription = FlutterCompass.events!.listen(
      (event) {
        if (event.heading == null) {
          print('[COMPASS_SERVICE] Evento recibido pero heading es null');
          return;
        }
        
        final newHeading = event.heading!;
        final now = DateTime.now();
        
        // Solo emitir si ha pasado suficiente tiempo y el cambio es significativo
        final timeDiff = now.difference(_lastUpdate).inMilliseconds;
        final headingDiff = (newHeading - _currentHeading).abs();
        
        print('[COMPASS_SERVICE] Evento - Nuevo heading: $newHeading°, Actual: $_currentHeading°, Diff: $headingDiff°, TimeDiff: ${timeDiff}ms');
        
        if (timeDiff >= minIntervalMs && headingDiff >= minHeadingChange) {
          _currentHeading = newHeading;
          _lastUpdate = now;
          print('[COMPASS_SERVICE] Emitiendo nuevo heading: $_currentHeading°');
          _headingController.add(_currentHeading);
        } else {
          print('[COMPASS_SERVICE] Ignorando cambio (timeDiff: $timeDiff < $minIntervalMs o headingDiff: $headingDiff < $minHeadingChange)');
        }
      },
      onError: (error) {
        print('[COMPASS_SERVICE] ERROR en stream: $error');
      },
      cancelOnError: false,
    );
    
    print('[COMPASS_SERVICE] Suscripción creada exitosamente');
  }

  /// Detiene la escucha de la brújula
  void stop() {
    print('[COMPASS_SERVICE] Deteniendo servicio...');
    _subscription?.cancel();
    _subscription = null;
    print('[COMPASS_SERVICE] Servicio detenido');
  }

  /// Libera recursos
  void dispose() {
    stop();
    _headingController.close();
  }
}
