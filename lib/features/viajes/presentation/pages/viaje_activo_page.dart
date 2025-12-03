import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/map_styles.dart';
import '../../../../core/services/directions_service.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../domain/entities/viaje.dart';
import '../bloc/viajes_provider.dart';

class ViajeActivoPage extends StatefulWidget {
  const ViajeActivoPage({super.key});

  @override
  State<ViajeActivoPage> createState() => _ViajeActivoPageState();
}

class _ViajeActivoPageState extends State<ViajeActivoPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  bool _isLoading = true;
  bool _isLoadingRoute = false;
  bool _followMode = true;

  // Ruta completa de navegación
  List<LatLng> _rutaCompleta = [];
  List<LatLng> _rutaRecorrida = [];

  // Marcadores personalizados
  BitmapDescriptor? _navigationArrow;
  BitmapDescriptor? _stopMarkerPending;
  BitmapDescriptor? _stopMarkerVisited;
  BitmapDescriptor? _stopMarkerStart;
  BitmapDescriptor? _stopMarkerEnd;

  // Animación
  late AnimationController _pulseController;

  // Colores de la ruta
  static const Color _colorRutaRecorrida = Color(0xFF9E9E9E); // Gris/Plomo
  static const Color _colorRutaPendiente = Color(0xFF4285F4); // Azul Google Maps
  static const Color _colorRutaBorde = Color(0xFF1A73E8); // Azul más oscuro

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomMarkers();
      _cargarViajeActivo();
    });
  }

  /// Crea el marcador de flecha de navegación (como Google Maps)
  Future<BitmapDescriptor> _createNavigationArrow() async {
    const double size = 60;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowPath = Path()
      ..moveTo(size / 2, 4)
      ..lineTo(size - 8, size - 8)
      ..lineTo(size / 2, size - 16)
      ..lineTo(8, size - 8)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Flecha principal (azul)
    final arrowPaint = Paint()
      ..color = _colorRutaPendiente
      ..style = PaintingStyle.fill;

    final arrowPath = Path()
      ..moveTo(size / 2, 0)
      ..lineTo(size - 6, size - 10)
      ..lineTo(size / 2, size - 18)
      ..lineTo(6, size - 10)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Borde blanco
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(arrowPath, borderPaint);

    // Punto central
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2 - 4), 6, centerPaint);

    final image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Carga los marcadores personalizados
  Future<void> _loadCustomMarkers() async {
    _navigationArrow = await _createNavigationArrow();
    _stopMarkerPending = await _createStopMarker(AppColors.warning, false);
    _stopMarkerVisited = await _createStopMarker(_colorRutaRecorrida, true);
    _stopMarkerStart = await _createStopMarker(Colors.green, false, isStart: true);
    _stopMarkerEnd = await _createStopMarker(Colors.red, false, isEnd: true);
    if (mounted) setState(() {});
  }

  /// Crea marcadores de paradero personalizados
  Future<BitmapDescriptor> _createStopMarker(
    Color color,
    bool visited, {
    bool isStart = false,
    bool isEnd = false,
  }) async {
    const double size = 32;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(size / 2, size / 2 + 1), size / 2 - 2, shadowPaint);

    // Círculo de fondo
    final bgPaint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, bgPaint);

    // Borde blanco
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, borderPaint);

    // Ícono interior
    final iconPaint = Paint()..color = Colors.white;
    if (isStart) {
      // Flecha de inicio
      final path = Path()
        ..moveTo(size * 0.35, size * 0.3)
        ..lineTo(size * 0.65, size * 0.5)
        ..lineTo(size * 0.35, size * 0.7)
        ..close();
      canvas.drawPath(path, iconPaint);
    } else if (isEnd) {
      // Bandera de fin
      canvas.drawRect(
        Rect.fromLTWH(size * 0.35, size * 0.25, 2, size * 0.5),
        iconPaint,
      );
      final flagPath = Path()
        ..moveTo(size * 0.37, size * 0.25)
        ..lineTo(size * 0.65, size * 0.35)
        ..lineTo(size * 0.37, size * 0.45)
        ..close();
      canvas.drawPath(flagPath, iconPaint);
    } else if (visited) {
      // Check mark
      final checkPath = Path()
        ..moveTo(size * 0.3, size * 0.5)
        ..lineTo(size * 0.45, size * 0.65)
        ..lineTo(size * 0.7, size * 0.35);
      canvas.drawPath(
        checkPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Círculo pequeño
      canvas.drawCircle(Offset(size / 2, size / 2), 4, iconPaint);
    }

    final image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  Future<void> _cargarViajeActivo() async {
    final authProvider = context.read<AuthProvider>();
    final viajesProvider = context.read<ViajesProvider>();
    final token = authProvider.user?.token;

    if (token != null) {
      await viajesProvider.cargarViajes(token: token);
      
      // Iniciar GPS automáticamente si hay viaje activo
      if (viajesProvider.viajeActivo != null) {
        await viajesProvider.iniciarGPSSiHayViajeActivo(token: token);
        await viajesProvider.obtenerPosicionActual();
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _cargarRutaNavegacion();
    }
  }

  /// Carga la ruta de navegación completa usando Google Directions API
  Future<void> _cargarRutaNavegacion() async {
    final viajesProvider = context.read<ViajesProvider>();
    final viaje = viajesProvider.viajeActivo;

    if (viaje == null || viaje.paraderos.isEmpty) return;

    setState(() => _isLoadingRoute = true);

    try {
      // Obtener coordenadas de los paraderos
      final paraderos = viaje.paraderos
          .map((p) => LatLng(p.latitud, p.longitud))
          .toList();

      // Llamar a Google Directions API para obtener ruta real por calles
      final routePoints = await DirectionsService.getRouteCoordinates(paraderos);

      if (mounted) {
        if (routePoints.isNotEmpty && routePoints.length > paraderos.length) {
          // Ruta obtenida de Directions API (tiene más puntos que los paraderos)
          setState(() {
            _rutaCompleta = routePoints;
          });
        } else {
          // Fallback: usar paraderos como puntos (líneas rectas)
          // Esto ocurre si la API key no tiene Directions API habilitada
          setState(() {
            _rutaCompleta = paraderos;
          });
        }
        _actualizarRutaConPosicion();
      }
    } catch (e) {
      // Error: usar paraderos como fallback
      if (mounted) {
        setState(() {
          _rutaCompleta = viaje.paraderos
              .map((p) => LatLng(p.latitud, p.longitud))
              .toList();
        });
        _actualizarRutaConPosicion();
      }
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  /// Encuentra el punto más cercano en la ruta a una posición dada
  int _encontrarPuntoMasCercano(LatLng posicion) {
    if (_rutaCompleta.isEmpty) return 0;

    int indiceMasCercano = 0;
    double distanciaMinima = double.infinity;

    for (int i = 0; i < _rutaCompleta.length; i++) {
      final distancia = _calcularDistancia(posicion, _rutaCompleta[i]);
      if (distancia < distanciaMinima) {
        distanciaMinima = distancia;
        indiceMasCercano = i;
      }
    }

    return indiceMasCercano;
  }

  /// Calcula la distancia entre dos puntos en metros
  double _calcularDistancia(LatLng p1, LatLng p2) {
    const double radioTierra = 6371000; // metros
    final lat1 = p1.latitude * math.pi / 180;
    final lat2 = p2.latitude * math.pi / 180;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return radioTierra * c;
  }

  /// Actualiza la ruta dividiendo en recorrida y pendiente basándose en la posición del bus
  void _actualizarRutaConPosicion() {
    final viajesProvider = context.read<ViajesProvider>();
    final viaje = viajesProvider.viajeActivo;
    final posicion = viajesProvider.posicionActual;

    if (viaje == null) return;

    final markers = <Marker>{};
    final circles = <Circle>{};
    final polylines = <Polyline>{};

    // Si no hay ruta cargada, usar los paraderos como puntos
    List<LatLng> rutaActual = _rutaCompleta.isNotEmpty 
        ? _rutaCompleta 
        : viaje.paraderos.map((p) => LatLng(p.latitud, p.longitud)).toList();

    if (rutaActual.isEmpty) return;

    // Encontrar el punto más cercano al bus en la ruta
    LatLng posicionBus;
    int indicePosicion = 0;
    double headingBus = 0;

    if (posicion != null) {
      posicionBus = LatLng(posicion.latitude, posicion.longitude);
      indicePosicion = _encontrarPuntoMasCercano(posicionBus);
      headingBus = posicion.heading;

      // Agregar la posición actual del bus a la ruta recorrida
      _rutaRecorrida = rutaActual.sublist(0, indicePosicion + 1);
      if (_rutaRecorrida.isNotEmpty) {
        _rutaRecorrida.add(posicionBus);
      }
    } else {
      // Sin GPS, usar el primer paradero como posición del bus
      posicionBus = LatLng(viaje.paraderos.first.latitud, viaje.paraderos.first.longitud);
      _rutaRecorrida = [];
    }

    // === POLYLINES ===

    // 1. Ruta RECORRIDA (GRIS/PLOMO) - Solo si hay GPS y ha avanzado
    if (_rutaRecorrida.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_recorrida_borde'),
          points: _rutaRecorrida,
          color: Colors.grey.shade700,
          width: 10,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_recorrida'),
          points: _rutaRecorrida,
          color: _colorRutaRecorrida,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }

    // 2. Ruta PENDIENTE (AZUL) - Toda la ruta si no hay GPS
    final rutaPendiente = <LatLng>[];
    if (posicion != null) {
      rutaPendiente.add(posicionBus);
      if (indicePosicion < rutaActual.length) {
        rutaPendiente.addAll(rutaActual.sublist(indicePosicion));
      }
    } else {
      // Sin GPS, mostrar toda la ruta en azul
      rutaPendiente.addAll(rutaActual);
    }

    if (rutaPendiente.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_pendiente_borde'),
          points: rutaPendiente,
          color: _colorRutaBorde,
          width: 10,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_pendiente'),
          points: rutaPendiente,
          color: _colorRutaPendiente,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }

    // === MARCADORES DE PARADEROS ===
    for (var i = 0; i < viaje.paraderos.length; i++) {
      final paradero = viaje.paraderos[i];
      final isFirst = i == 0;
      final isLast = i == viaje.paraderos.length - 1;

      BitmapDescriptor markerIcon;
      if (isFirst) {
        markerIcon = _stopMarkerStart ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (isLast) {
        markerIcon = _stopMarkerEnd ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      } else if (paradero.visitado) {
        markerIcon = _stopMarkerVisited ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      } else {
        markerIcon = _stopMarkerPending ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }

      markers.add(
        Marker(
          markerId: MarkerId('paradero_$i'),
          position: LatLng(paradero.latitud, paradero.longitud),
          icon: markerIcon,
          anchor: const Offset(0.5, 0.5),
          zIndex: 10,
          infoWindow: InfoWindow(
            title: '${i + 1}. ${paradero.nombre}',
            snippet: paradero.visitado ? '✓ Visitado' : 'Pendiente',
          ),
        ),
      );
    }

    // === MARCADOR DEL BUS (FLECHA DE NAVEGACIÓN) - SIEMPRE VISIBLE ===
    markers.add(
      Marker(
        markerId: const MarkerId('bus_navegacion'),
        position: posicionBus,
        icon: _navigationArrow ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        anchor: const Offset(0.5, 0.5),
        rotation: headingBus,
        flat: true,
        zIndex: 100,
        infoWindow: InfoWindow(
          title: 'Tu Bus',
          snippet: posicion != null 
              ? '${(posicion.speed * 3.6).toStringAsFixed(0)} km/h'
              : 'Esperando GPS...',
        ),
      ),
    );

    // Círculo de precisión GPS (solo si hay GPS)
    if (posicion != null) {
      circles.add(
        Circle(
          circleId: const CircleId('precision_gps'),
          center: posicionBus,
          radius: posicion.accuracy > 0 ? posicion.accuracy : 15,
          fillColor: _colorRutaPendiente.withOpacity(0.1),
          strokeColor: _colorRutaPendiente.withOpacity(0.3),
          strokeWidth: 1,
        ),
      );

      // Mover cámara si está en modo seguimiento
      if (_followMode && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: posicionBus,
              zoom: 18,
              bearing: headingBus,
              tilt: 60,
            ),
          ),
        );
      }
    } else {
      // Sin GPS, centrar en la posición del bus (primer paradero)
      if (_followMode && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: posicionBus,
              zoom: 16,
              tilt: 45,
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
      _circles = circles;
    });
  }

  Future<void> _finalizarViaje() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Text('¿Finalizar viaje?'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas finalizar el viaje actual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final viajesProvider = context.read<ViajesProvider>();
    final token = authProvider.user?.token;

    if (token == null) return;

    AppGradientSpinner.showOverlay(context, message: 'Finalizando viaje...');
    final success = await viajesProvider.finalizarViaje(token: token);

    if (!mounted) return;
    AppGradientSpinner.hideOverlay(context);

    if (success) {
      AppToast.show(context, message: '¡Viaje finalizado!', type: ToastType.success);
      context.go('/home');
    } else {
      AppToast.show(context, message: viajesProvider.error ?? 'Error', type: ToastType.error);
    }
  }

  void _centrarEnRuta() {
    final viajesProvider = context.read<ViajesProvider>();
    final viaje = viajesProvider.viajeActivo;
    if (viaje == null || viaje.paraderos.isEmpty) return;

    final points = viaje.paraderos.map((p) => LatLng(p.latitud, p.longitud)).toList();
    final bounds = _calcularBounds(points);

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    setState(() => _followMode = false);
  }

  LatLngBounds _calcularBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Calcula la distancia al próximo paradero
  String _calcularDistanciaAlProximoParadero(Position? posicion, Paradero proximoParadero) {
    if (posicion == null) return '--';

    final distancia = _calcularDistancia(
      LatLng(posicion.latitude, posicion.longitude),
      LatLng(proximoParadero.latitud, proximoParadero.longitud),
    );

    if (distancia < 1000) {
      return '${distancia.toStringAsFixed(0)} m';
    } else {
      return '${(distancia / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viajesProvider = context.watch<ViajesProvider>();
    final viaje = viajesProvider.viajeActivo;
    final posicion = viajesProvider.posicionActual;

    if (_isLoading || viajesProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: const Center(child: AppGradientSpinner()),
      );
    }

    if (viaje == null) {
      return _buildNoViajeWidget();
    }

    // Actualizar ruta cuando cambia la posición
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarRutaConPosicion();
    });

    final initialPosition = posicion != null
        ? LatLng(posicion.latitude, posicion.longitude)
        : viaje.paraderos.isNotEmpty
            ? LatLng(viaje.paraderos.first.latitud, viaje.paraderos.first.longitud)
            : const LatLng(-12.0464, -77.0428);

    // Encontrar próximo paradero
    final paraderosPendientes = viaje.paraderos.where((Paradero p) => !p.visitado);
    final proximoParadero = paraderosPendientes.isNotEmpty
        ? paraderosPendientes.first
        : viaje.paraderos.last;
    final paraderoIndex = viaje.paraderos.indexOf(proximoParadero) + 1;
    final distanciaProximo = _calcularDistanciaAlProximoParadero(posicion, proximoParadero);

    return Scaffold(
      body: Stack(
        children: [
          // === MAPA ===
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 18,
              tilt: 60,
              bearing: posicion?.heading ?? 0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle(MapStyles.navigationStyle);
              _cargarRutaNavegacion();
            },
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            onCameraMoveStarted: () {
              if (_followMode) setState(() => _followMode = false);
            },
          ),

          // === BANNER DE NAVEGACIÓN (COLORES NETTALCO) ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.navyDark, // Color primario NETTALCO
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Fila principal de navegación
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          // Ícono de dirección
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.blueLight, // Azul NETTALCO
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Distancia y nombre del paradero
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  distanciaProximo,
                                  style: TextStyle(
                                    color: AppColors.mintLight, // Mint NETTALCO
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  proximoParadero.nombre,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Botón de volver
                          IconButton(
                            onPressed: () => context.go('/home'),
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Siguiente indicación
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppColors.navyDarker, // Navy más oscuro
                      child: Row(
                        children: [
                          Text(
                            'Siguiente',
                            style: TextStyle(
                              color: AppColors.mintLight.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: AppColors.blueLight, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              paraderoIndex < viaje.paraderos.length
                                  ? viaje.paraderos[paraderoIndex].nombre
                                  : 'Fin del recorrido',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === CONTROLES DEL MAPA ===
          Positioned(
            right: 16,
            bottom: 280,
            child: Column(
              children: [
                _buildMapButton(
                  icon: _followMode ? Icons.gps_fixed : Icons.gps_not_fixed,
                  onPressed: () {
                    setState(() => _followMode = !_followMode);
                    if (_followMode && posicion != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(posicion.latitude, posicion.longitude),
                            zoom: 18,
                            bearing: posicion.heading,
                            tilt: 60,
                          ),
                        ),
                      );
                    }
                  },
                  isActive: _followMode,
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.layers_outlined,
                  onPressed: _centrarEnRuta,
                ),
              ],
            ),
          ),

          // === INDICADOR DE VELOCIDAD ===
          Positioned(
            left: 16,
            bottom: 280,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.navyDark,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
                border: Border.all(color: AppColors.blueLight, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    posicion != null 
                        ? '${(posicion.speed * 3.6).toStringAsFixed(0)}'
                        : '--',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mintLight,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.blueLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === INDICADOR DE CARGA ===
          if (_isLoadingRoute)
            Positioned(
              top: MediaQuery.of(context).padding.top + 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text('Cargando ruta...', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // === PANEL INFERIOR ===
          _buildBottomPanel(viaje, posicion, paraderoIndex),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Material(
      elevation: 4,
      shadowColor: AppColors.navyDark.withOpacity(0.3),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.blueLight : AppColors.white,
            border: Border.all(
              color: isActive ? AppColors.blueLight : AppColors.navyDark.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.white : AppColors.navyDark,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(Viaje viaje, Position? posicion, int paraderoIndex) {
    final visitados = viaje.paraderos.where((p) => p.visitado).length;
    final total = viaje.paraderos.length;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de arrastre
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.navyDark.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Info del viaje
                Row(
                  children: [
                    // Paraderos
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.blueLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$visitados/$total',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blueLight,
                              ),
                            ),
                            Text(
                              'Paraderos',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Placa del bus
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.navyDark.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              viaje.placaBus,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyDark,
                              ),
                            ),
                            Text(
                              'Bus',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // GPS Status
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: posicion != null 
                              ? AppColors.mintLight.withOpacity(0.2)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              posicion != null ? Icons.gps_fixed : Icons.gps_off,
                              color: posicion != null ? AppColors.mintDarker : AppColors.error,
                              size: 24,
                            ),
                            Text(
                              posicion != null ? 'GPS OK' : 'Sin GPS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: posicion != null ? AppColors.mintDarker : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Botón finalizar
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _finalizarViaje,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text(
                      'FINALIZAR VIAJE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoViajeWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viaje'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.navyDark.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_bus, size: 80, color: AppColors.navyDark),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay viaje activo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia un viaje desde "Mis Viajes"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/mis-viajes'),
              icon: const Icon(Icons.list_alt),
              label: const Text('Ir a Mis Viajes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blueLight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
