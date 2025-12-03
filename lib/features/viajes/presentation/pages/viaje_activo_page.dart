import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../bloc/viajes_provider.dart';

class ViajeActivoPage extends StatefulWidget {
  const ViajeActivoPage({super.key});

  @override
  State<ViajeActivoPage> createState() => _ViajeActivoPageState();
}

class _ViajeActivoPageState extends State<ViajeActivoPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarViajeActivo();
    });
  }

  Future<void> _cargarViajeActivo() async {
    final authProvider = context.read<AuthProvider>();
    final viajesProvider = context.read<ViajesProvider>();
    final token = authProvider.user?.token;

    if (token != null) {
      await viajesProvider.cargarViajes(token: token);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _actualizarMapa();
    }
  }

  void _actualizarMapa() {
    final viajesProvider = context.read<ViajesProvider>();
    final viaje = viajesProvider.viajeActivo;
    final posicion = viajesProvider.posicionActual;

    if (viaje == null) return;

    final markers = <Marker>{};
    final polylinePoints = <LatLng>[];

    // Agregar marcadores de paraderos
    for (var i = 0; i < viaje.paraderos.length; i++) {
      final paradero = viaje.paraderos[i];
      final isFirst = i == 0;
      final isLast = i == viaje.paraderos.length - 1;

      markers.add(
        Marker(
          markerId: MarkerId('paradero_$i'),
          position: LatLng(paradero.latitud, paradero.longitud),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isFirst
                ? BitmapDescriptor.hueGreen
                : isLast
                    ? BitmapDescriptor.hueRed
                    : paradero.visitado
                        ? BitmapDescriptor.hueAzure
                        : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: paradero.nombre,
            snippet: paradero.visitado ? '✓ Visitado' : 'Pendiente',
          ),
        ),
      );

      polylinePoints.add(LatLng(paradero.latitud, paradero.longitud));
    }

    // Agregar marcador de posición actual
    if (posicion != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('mi_posicion'),
          position: LatLng(posicion.latitude, posicion.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Mi posición',
            snippet: '${(posicion.speed * 3.6).toStringAsFixed(0)} km/h',
          ),
          zIndex: 100,
        ),
      );

      // Mover cámara a posición actual
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(posicion.latitude, posicion.longitude)),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('ruta'),
          points: polylinePoints,
          color: AppColors.blueLight,
          width: 4,
        ),
      };
    });
  }

  Future<void> _finalizarViaje() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar viaje?'),
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
      AppToast.show(
        context,
        message: '¡Viaje finalizado correctamente!',
        type: ToastType.success,
      );
      context.go('/home');
    } else {
      AppToast.show(
        context,
        message: viajesProvider.error ?? 'Error al finalizar viaje',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viajesProvider = context.watch<ViajesProvider>();
    final viaje = viajesProvider.viajeActivo;
    final posicion = viajesProvider.posicionActual;

    // Mostrar spinner mientras carga
    if (_isLoading || viajesProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Viaje'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: AppGradientSpinner()),
      );
    }

    if (viaje == null) {
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
              Icon(Icons.directions_bus, size: 80, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No hay viaje activo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia un viaje desde "Mis Viajes"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/mis-viajes'),
                child: const Text('Ir a Mis Viajes'),
              ),
            ],
          ),
        ),
      );
    }

    // Escuchar cambios de posición para actualizar mapa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarMapa();
    });

    final initialPosition = posicion != null
        ? LatLng(posicion.latitude, posicion.longitude)
        : viaje.paraderos.isNotEmpty
            ? LatLng(viaje.paraderos.first.latitud, viaje.paraderos.first.longitud)
            : const LatLng(-12.0464, -77.0428); // Lima por defecto

    return Scaffold(
      appBar: AppBar(
        title: Text(viaje.nombreRuta),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          // Indicador GPS
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: viajesProvider.gpsActivo
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  viajesProvider.gpsActivo ? Icons.gps_fixed : Icons.gps_off,
                  size: 16,
                  color: viajesProvider.gpsActivo ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  viajesProvider.gpsActivo ? 'GPS' : 'Sin GPS',
                  style: TextStyle(
                    fontSize: 12,
                    color: viajesProvider.gpsActivo ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapa
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _actualizarMapa();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // Panel de información
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info del viaje
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Bus
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.directions_bus,
                            label: 'Bus',
                            value: viaje.placaBus,
                          ),
                        ),
                        // Velocidad
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.speed,
                            label: 'Velocidad',
                            value: posicion != null
                                ? '${(posicion.speed * 3.6).toStringAsFixed(0)} km/h'
                                : '-- km/h',
                          ),
                        ),
                        // Paraderos
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.location_on,
                            label: 'Paraderos',
                            value: '${viaje.paraderos.where((p) => p.visitado).length}/${viaje.paraderos.length}',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Próximo paradero
                  if (viaje.paraderos.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: AppColors.blueLight.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: AppColors.blueLight),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Próximo paradero',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  viaje.paraderos
                                      .firstWhere(
                                        (p) => !p.visitado,
                                        orElse: () => viaje.paraderos.last,
                                      )
                                      .nombre,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Botón finalizar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _finalizarViaje,
                        icon: const Icon(Icons.stop),
                        label: const Text('FINALIZAR VIAJE'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.blueLight, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

