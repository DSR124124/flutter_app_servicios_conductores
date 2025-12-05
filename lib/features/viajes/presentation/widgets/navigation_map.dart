import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/map_styles.dart';
import '../../../../core/services/compass_service.dart';
import '../../../../core/services/directions_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../domain/entities/viaje.dart';
import 'navigation_instruction_card.dart';

/// Widget de mapa de navegación con soporte para brújula y rutas
class NavigationMap extends StatefulWidget {
  final Viaje viaje;
  final Position? currentPosition;
  final Paradero? siguienteParadero;
  final bool followMode;
  final VoidCallback? onFollowModeChanged;
  final Function(GoogleMapController)? onMapCreated;

  const NavigationMap({
    super.key,
    required this.viaje,
    this.currentPosition,
    this.siguienteParadero,
    this.followMode = true,
    this.onFollowModeChanged,
    this.onMapCreated,
  });

  @override
  State<NavigationMap> createState() => _NavigationMapState();
}

class _NavigationMapState extends State<NavigationMap> {
  GoogleMapController? _mapController;
  final CompassService _compassService = CompassService();
  final NavigationService _navigationService = NavigationService();
  StreamSubscription<double>? _compassSubscription;
  StreamSubscription<Position>? _navigationPositionSubscription;
  StreamSubscription<NavigationInstruction?>? _instructionSubscription;
  StreamSubscription<List<LatLng>>? _routeSubscription;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  
  List<LatLng> _rutaPendiente = [];
  List<LatLng> _rutaRecorrida = [];
  bool _isLoadingRoute = false;
  
  NavigationInstruction? _currentInstruction;
  bool _navigationActive = false;
  
  // Marcadores personalizados
  BitmapDescriptor? _busMarker;
  BitmapDescriptor? _stopMarkerPending;
  BitmapDescriptor? _stopMarkerVisited;
  BitmapDescriptor? _stopMarkerStart;
  BitmapDescriptor? _stopMarkerEnd;

  static const Color _colorRutaRecorrida = Color(0xFF9E9E9E);
  static const Color _colorRutaPendiente = Color(0xFF4285F4);
  static const Color _colorRutaBorde = Color(0xFF1A73E8);

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _startCompass();
    _cargarRutas();
  }

  @override
  void didUpdateWidget(NavigationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('[MAP] didUpdateWidget - followMode: ${oldWidget.followMode} -> ${widget.followMode}, position changed: ${oldWidget.currentPosition != widget.currentPosition}');
    if (oldWidget.viaje.paraderos != widget.viaje.paraderos) {
      print('[MAP] Paraderos cambiaron, recargando rutas...');
      _cargarRutas();
    }
    if (oldWidget.currentPosition != widget.currentPosition) {
      print('[MAP] Posición GPS cambió, actualizando mapa...');
      _actualizarMapa();
    }
    if (oldWidget.followMode != widget.followMode) {
      print('[MAP] FollowMode cambió: ${oldWidget.followMode} -> ${widget.followMode}');
      widget.followMode ? _startCompass() : _stopCompass();
    }
  }

  @override
  void dispose() {
    _stopCompass();
    _stopNavigation();
    _mapController?.dispose();
    super.dispose();
  }
  
  void _stopNavigation() {
    _navigationPositionSubscription?.cancel();
    _instructionSubscription?.cancel();
    _routeSubscription?.cancel();
    _navigationService.stopNavigation();
  }

  void _startCompass() {
    if (!widget.followMode) {
      print('[COMPASS] No se inicia brújula: followMode = false');
      return;
    }
    print('[COMPASS] Iniciando brújula...');
    // Reducir umbral para mayor sensibilidad
    _compassService.start(minIntervalMs: 50, minHeadingChange: 2.0);
    _compassSubscription = _compassService.headingStream.listen(
      _onCompassUpdate,
      onError: (error) {
        print('[COMPASS] Error en stream: $error');
      },
    );
    print('[COMPASS] Brújula iniciada. Heading inicial: ${_compassService.currentHeading}°');
  }

  void _stopCompass() {
    print('[COMPASS] Deteniendo brújula...');
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _compassService.stop();
    print('[COMPASS] Brújula detenida');
  }

  void _onCompassUpdate(double heading) {
    if (_mapController == null || !widget.followMode || !mounted) return;
    final target = _getTargetPosition();
    if (target == null) return;
    
    print('[COMPASS] Heading actualizado: $heading°');
    
    // Actualizar la cámara con el nuevo bearing
    _mapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: target, zoom: 18, bearing: heading, tilt: 60),
    ));
    
    // Actualizar el marcador del bus para que rote
    _actualizarMapa();
  }

  LatLng? _getTargetPosition() {
    if (widget.currentPosition != null) {
      return LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude);
    }
    if (widget.siguienteParadero != null) {
      return LatLng(widget.siguienteParadero!.latitud, widget.siguienteParadero!.longitud);
    }
    if (widget.viaje.paraderos.isNotEmpty) {
      return LatLng(widget.viaje.paraderos.first.latitud, widget.viaje.paraderos.first.longitud);
    }
    return null;
  }

  Future<void> _loadCustomMarkers() async {
    _busMarker = await _createBusMarker();
    _stopMarkerPending = await _createStopMarker(AppColors.warning, false);
    _stopMarkerVisited = await _createStopMarker(_colorRutaRecorrida, true);
    _stopMarkerStart = await _createStopMarker(Colors.green, false, isStart: true);
    _stopMarkerEnd = await _createStopMarker(Colors.red, false, isEnd: true);
    if (mounted) _actualizarMapa();
  }

  Future<void> _cargarRutas() async {
    if (widget.viaje.paraderos.isEmpty) return;
    setState(() => _isLoadingRoute = true);
    
    try {
      final visitados = widget.viaje.paraderos.where((p) => p.estaVisitado).toList();
      final pendientes = widget.viaje.paraderos.where((p) => !p.estaVisitado).toList();

      // Ruta recorrida
      if (visitados.length >= 2) {
        final puntos = visitados.map((p) => LatLng(p.latitud, p.longitud)).toList();
        final ruta = await DirectionsService.getRouteCoordinates(puntos);
        if (mounted && ruta.isNotEmpty) _rutaRecorrida = ruta;
      } else {
        _rutaRecorrida = [];
      }

      // Ruta pendiente con navegación en tiempo real
      if (pendientes.isNotEmpty && widget.currentPosition != null) {
        final puntos = <LatLng>[];
        puntos.add(LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude));
        for (final p in pendientes) {
          puntos.add(LatLng(p.latitud, p.longitud));
        }
        
        if (puntos.length >= 2) {
          // Obtener ruta completa con instrucciones
          final navResponse = await DirectionsService.getNavigationRoute(puntos);
          
          if (mounted && navResponse != null) {
            _rutaPendiente = navResponse.route;
            
            // Iniciar navegación en tiempo real
            await _startNavigation(navResponse);
          } else {
            // Fallback a ruta simple
            final ruta = await DirectionsService.getRouteCoordinates(puntos);
            if (mounted) _rutaPendiente = ruta.isNotEmpty ? ruta : puntos;
          }
        }
      } else if (pendientes.isNotEmpty) {
        // Sin GPS, usar ruta simple
        final puntos = <LatLng>[];
        if (visitados.isNotEmpty) {
          puntos.add(LatLng(visitados.last.latitud, visitados.last.longitud));
        }
        for (final p in pendientes) {
          puntos.add(LatLng(p.latitud, p.longitud));
        }
        if (puntos.length >= 2) {
          final ruta = await DirectionsService.getRouteCoordinates(puntos);
          if (mounted) _rutaPendiente = ruta.isNotEmpty ? ruta : puntos;
        }
      } else {
        _rutaPendiente = [];
      }

      if (mounted) _actualizarMapa();
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }
  
  Future<void> _startNavigation(NavigationResponse route) async {
    if (_navigationActive) {
      _navigationService.stopNavigation();
    }
    
    try {
      await _navigationService.startNavigation(route);
      _navigationActive = true;
      
      // Escuchar actualizaciones de posición
      _navigationPositionSubscription = _navigationService.positionStream.listen(
        (position) {
          if (mounted) {
            setState(() {
              // La posición se actualiza automáticamente desde widget.currentPosition
            });
            _actualizarMapa();
          }
        },
      );
      
      // Escuchar instrucciones
      _instructionSubscription = _navigationService.instructionStream.listen(
        (instruction) {
          if (mounted) {
            setState(() {
              _currentInstruction = instruction;
            });
          }
        },
      );
      
      // Escuchar cambios de ruta (recalculaciones)
      _routeSubscription = _navigationService.routeStream.listen(
        (route) {
          if (mounted) {
            setState(() {
              _rutaPendiente = route;
            });
            _actualizarMapa();
          }
        },
      );
      
      print('[MAP] Navegación en tiempo real iniciada');
    } catch (e) {
      print('[MAP] Error al iniciar navegación: $e');
    }
  }

  void _actualizarMapa() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};
    final circles = <Circle>{};

    // Polylines
    if (_rutaRecorrida.length >= 2) {
      polylines.add(Polyline(polylineId: const PolylineId('recorrida_borde'), points: _rutaRecorrida, color: Colors.grey.shade700, width: 10));
      polylines.add(Polyline(polylineId: const PolylineId('recorrida'), points: _rutaRecorrida, color: _colorRutaRecorrida, width: 6));
    }
    if (_rutaPendiente.length >= 2) {
      polylines.add(Polyline(polylineId: const PolylineId('pendiente_borde'), points: _rutaPendiente, color: _colorRutaBorde, width: 10));
      polylines.add(Polyline(polylineId: const PolylineId('pendiente'), points: _rutaPendiente, color: _colorRutaPendiente, width: 6));
    }

    // Paraderos
    for (int i = 0; i < widget.viaje.paraderos.length; i++) {
      final p = widget.viaje.paraderos[i];
      final esSiguiente = widget.siguienteParadero?.idParadero == p.idParadero;
      
      BitmapDescriptor icon;
      if (i == 0) {
        icon = _stopMarkerStart ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (i == widget.viaje.paraderos.length - 1) {
        icon = _stopMarkerEnd ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      } else if (p.estaVisitado) {
        icon = _stopMarkerVisited ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      } else {
        icon = _stopMarkerPending ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }

      markers.add(Marker(
        markerId: MarkerId('paradero_$i'),
        position: LatLng(p.latitud, p.longitud),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        zIndex: esSiguiente ? 50 : (p.estaVisitado ? 5 : 10),
        infoWindow: InfoWindow(title: '#${p.orden}. ${p.nombre}'),
      ));
    }

    // Bus
    if (widget.currentPosition != null) {
      final pos = widget.currentPosition!;
      final busRotation = widget.followMode 
          ? _compassService.currentHeading 
          : (pos.heading.isNaN ? 0.0 : pos.heading.toDouble());
      print('[MAP] Actualizando marcador bus - Posición: (${pos.latitude}, ${pos.longitude}), Rotación: $busRotation°, FollowMode: ${widget.followMode}');
      markers.add(Marker(
        markerId: const MarkerId('bus'),
        position: LatLng(pos.latitude, pos.longitude),
        icon: _busMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        anchor: const Offset(0.5, 0.5),
        rotation: busRotation,
        flat: true,
        zIndex: 100,
      ));
      circles.add(Circle(
        circleId: const CircleId('gps'),
        center: LatLng(pos.latitude, pos.longitude),
        radius: pos.accuracy > 0 ? pos.accuracy : 15,
        fillColor: _colorRutaPendiente.withOpacity(0.1),
        strokeColor: _colorRutaPendiente.withOpacity(0.3),
        strokeWidth: 1,
      ));
    }

    setState(() { _markers = markers; _polylines = polylines; _circles = circles; });
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = _getTargetPosition() ?? const LatLng(-12.0464, -77.0428);
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initialPos, zoom: 15, tilt: widget.followMode ? 60 : 0),
          markers: _markers,
          polylines: _polylines,
          circles: _circles,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          style: MapStyles.navigationStyle,
          onMapCreated: (c) { _mapController = c; widget.onMapCreated?.call(c); _actualizarMapa(); },
          onCameraMoveStarted: () { if (widget.followMode) widget.onFollowModeChanged?.call(); },
        ),
        if (_isLoadingRoute) const _LoadingRouteIndicator(),
        // Instrucción de navegación
        if (_currentInstruction != null && _navigationActive)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: NavigationInstructionCard(
              instruction: _currentInstruction,
              totalDistance: _navigationService.currentRoute?.totalDistance,
              totalDuration: _navigationService.currentRoute?.totalDuration,
            ),
          ),
      ],
    );
  }

  // === MARCADORES ===
  Future<BitmapDescriptor> _createBusMarker() async {
    const w = 100.0, h = 140.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final cx = w / 2, cy = h / 2;
    const bw = 50.0, bh = 90.0;

    // Sombra
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 4, cy + 6), width: bw, height: bh), const Radius.circular(12)),
      Paint()..color = Colors.black.withOpacity(0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Cuerpo 3D
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 2, cy + 2), width: bw, height: bh), const Radius.circular(12)),
      Paint()..color = const Color(0xFF1565C0));
    // Cuerpo principal
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh), const Radius.circular(12)),
      Paint()..shader = ui.Gradient.linear(Offset(cx - bw/2, cy), Offset(cx + bw/2, cy), [const Color(0xFF42A5F5), const Color(0xFF1E88E5), const Color(0xFF1565C0)], [0, 0.5, 1]));
    // Borde
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh), const Radius.circular(12)),
      Paint()..color = const Color(0xFFE3F2FD)..style = PaintingStyle.stroke..strokeWidth = 2.5);
    // Techo
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: bw - 10, height: bh - 14), const Radius.circular(8)),
      Paint()..shader = ui.Gradient.linear(Offset(cx - bw/2, cy - bh/2), Offset(cx + bw/2, cy + bh/2), [const Color(0xFF90CAF9), const Color(0xFF64B5F6)], [0, 1]));
    // Luces
    c.drawCircle(Offset(cx - 14, cy - bh/2 + 10), 4, Paint()..color = const Color(0xFFFFEB3B));
    c.drawCircle(Offset(cx + 14, cy - bh/2 + 10), 4, Paint()..color = const Color(0xFFFFEB3B));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 16, cy + bh/2 - 10, 8, 5), const Radius.circular(2)), Paint()..color = const Color(0xFFEF5350));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 8, cy + bh/2 - 10, 8, 5), const Radius.circular(2)), Paint()..color = const Color(0xFFEF5350));
    // Ruedas
    final wp = Paint()..color = const Color(0xFF37474F);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw/2 - 4, cy - 25, 8, 18), const Radius.circular(3)), wp);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + bw/2 - 4, cy - 25, 8, 18), const Radius.circular(3)), wp);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw/2 - 5, cy + 15, 10, 22), const Radius.circular(4)), wp);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + bw/2 - 5, cy + 15, 10, 22), const Radius.circular(4)), wp);
    // Flecha
    final arrow = Path()..moveTo(cx, cy - bh/2 - 15)..lineTo(cx - 10, cy - bh/2 - 2)..lineTo(cx - 4, cy - bh/2 - 2)..lineTo(cx - 4, cy - bh/2 + 5)..lineTo(cx + 4, cy - bh/2 + 5)..lineTo(cx + 4, cy - bh/2 - 2)..lineTo(cx + 10, cy - bh/2 - 2)..close();
    c.drawPath(arrow, Paint()..color = Colors.white);
    c.drawPath(arrow, Paint()..color = const Color(0xFF1565C0)..style = PaintingStyle.stroke..strokeWidth = 2);

    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createStopMarker(Color color, bool visited, {bool isStart = false, bool isEnd = false}) async {
    const s = 32.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawCircle(Offset(s/2, s/2 + 1), s/2 - 2, Paint()..color = Colors.black.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    c.drawCircle(Offset(s/2, s/2), s/2 - 2, Paint()..color = color);
    c.drawCircle(Offset(s/2, s/2), s/2 - 2, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    
    final ip = Paint()..color = Colors.white;
    if (isStart) {
      c.drawPath(Path()..moveTo(s * 0.35, s * 0.3)..lineTo(s * 0.65, s * 0.5)..lineTo(s * 0.35, s * 0.7)..close(), ip);
    } else if (isEnd) {
      c.drawRect(Rect.fromLTWH(s * 0.35, s * 0.25, 2, s * 0.5), ip);
      c.drawPath(Path()..moveTo(s * 0.37, s * 0.25)..lineTo(s * 0.65, s * 0.35)..lineTo(s * 0.37, s * 0.45)..close(), ip);
    } else if (visited) {
      c.drawPath(Path()..moveTo(s * 0.3, s * 0.5)..lineTo(s * 0.45, s * 0.65)..lineTo(s * 0.7, s * 0.35), Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
    } else {
      c.drawCircle(Offset(s/2, s/2), 4, ip);
    }
    
    final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }
}

class _LoadingRouteIndicator extends StatelessWidget {
  const _LoadingRouteIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 8),
              Text('Cargando ruta...', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
