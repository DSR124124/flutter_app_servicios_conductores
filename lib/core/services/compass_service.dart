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
    if (_subscription != null) return;
    
    _subscription = FlutterCompass.events?.listen((event) {
      if (event.heading == null) return;
      
      final newHeading = event.heading!;
      final now = DateTime.now();
      
      // Solo emitir si ha pasado suficiente tiempo y el cambio es significativo
      final timeDiff = now.difference(_lastUpdate).inMilliseconds;
      final headingDiff = (newHeading - _currentHeading).abs();
      
      if (timeDiff >= minIntervalMs && headingDiff >= minHeadingChange) {
        _currentHeading = newHeading;
        _lastUpdate = now;
        _headingController.add(_currentHeading);
      }
    });
  }

  /// Detiene la escucha de la brújula
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Libera recursos
  void dispose() {
    stop();
    _headingController.close();
  }
}
