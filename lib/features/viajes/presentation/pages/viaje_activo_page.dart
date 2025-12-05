import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../domain/entities/llegada_paradero.dart';
import '../../domain/entities/viaje.dart';
import '../bloc/viajes_provider.dart';
import '../widgets/widgets.dart';

class ViajeActivoPage extends StatefulWidget {
  const ViajeActivoPage({super.key});

  @override
  State<ViajeActivoPage> createState() => _ViajeActivoPageState();
}

class _ViajeActivoPageState extends State<ViajeActivoPage> {
  GoogleMapController? _mapController;
  bool _isLoading = true;
  bool _followMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarViajeActivo());
  }

  Future<void> _cargarViajeActivo() async {
    final auth = context.read<AuthProvider>();
    final viajes = context.read<ViajesProvider>();
    final token = auth.user?.token;

    if (token != null) {
      await viajes.cargarViajes(token: token);
      if (viajes.viajeActivo != null) {
        await viajes.iniciarGPSSiHayViajeActivo(token: token);
        await viajes.obtenerPosicionActual();
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _centrarEnMiUbicacion() {
    final pos = context.read<ViajesProvider>().posicionActual;
    if (pos != null && _mapController != null) {
      setState(() => _followMode = true);
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 18, tilt: 60),
      ));
    }
  }

  void _centrarEnRuta() {
    final viaje = context.read<ViajesProvider>().viajeActivo;
    if (viaje == null || viaje.paraderos.isEmpty || _mapController == null) return;

    setState(() => _followMode = false);
    final bounds = LatLngBounds(
      southwest: LatLng(
        viaje.paraderos.map((p) => p.latitud).reduce((a, b) => a < b ? a : b),
        viaje.paraderos.map((p) => p.longitud).reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        viaje.paraderos.map((p) => p.latitud).reduce((a, b) => a > b ? a : b),
        viaje.paraderos.map((p) => p.longitud).reduce((a, b) => a > b ? a : b),
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ViajesProvider>(
      builder: (context, viajes, _) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: AppGradientSpinner()),
          );
        }

        final viaje = viajes.viajeActivo;
        if (viaje == null) return _buildNoViajeWidget();

        final posicion = viajes.posicionActual;
        final siguiente = viajes.siguienteParadero;
        final todosVisitados = viajes.todosParaderosVisitados;
        final visitados = viaje.paraderos.where((p) => p.estaVisitado).length;

        return Scaffold(
          body: Stack(
            children: [
              // Mapa
              NavigationMap(
                viaje: viaje,
                currentPosition: posicion,
                siguienteParadero: siguiente,
                followMode: _followMode,
                onFollowModeChanged: () => setState(() => _followMode = false),
                onMapCreated: (c) => _mapController = c,
              ),

              // Banner superior
              if (siguiente != null && !todosVisitados)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: TripInfoBanner(
                    paradero: siguiente,
                    visitados: visitados,
                    total: viaje.paraderos.length,
                  ),
                ),

              // Controles del mapa
              Positioned(
                right: 16,
                bottom: 300,
                child: MapControls(
                  followMode: _followMode,
                  onCenterLocation: _centrarEnMiUbicacion,
                  onShowRoute: _centrarEnRuta,
                ),
              ),

              // Velocímetro
              if (posicion != null)
                Positioned(
                  left: 16,
                  bottom: 300,
                  child: SpeedIndicator(position: posicion),
                ),

              // Panel inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: TripBottomPanel(
                  viaje: viaje,
                  siguienteParadero: siguiente,
                  todosVisitados: todosVisitados,
                  onMarcarLlegada: siguiente != null ? () => _marcarLlegadaParadero(siguiente) : null,
                  onFinalizarViaje: _finalizarViaje,
                ),
              ),
            ],
          ),
        );
      },
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

  // === ACCIONES ===

  Future<void> _finalizarViaje() async {
    final confirm = await _showConfirmDialog(
      title: '¿Finalizar viaje?',
      content: '¿Estás seguro de que deseas finalizar el viaje actual?',
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.error,
      confirmText: 'Finalizar',
      confirmColor: AppColors.error,
    );

    if (confirm != true || !mounted) return;

    final token = context.read<AuthProvider>().user?.token;
    if (token == null) return;

    AppGradientSpinner.showOverlay(context, message: 'Finalizando viaje...');
    final success = await context.read<ViajesProvider>().finalizarViaje(token: token);

    if (!mounted) return;
    AppGradientSpinner.hideOverlay(context);

    if (success) {
      AppToast.show(context, message: '¡Viaje finalizado!', type: ToastType.success);
      context.go('/home');
    } else {
      AppToast.show(context, message: context.read<ViajesProvider>().error ?? 'Error', type: ToastType.error);
    }
  }

  Future<void> _marcarLlegadaParadero(Paradero paradero) async {
    final confirm = await _showConfirmDialog(
      title: 'Marcar llegada',
      content: '¿Confirmas que llegaste a:\n\n${paradero.nombre}',
      icon: Icons.location_on,
      iconColor: AppColors.mintDarker,
      confirmText: 'Confirmar',
      confirmColor: AppColors.mintDarker,
    );

    if (confirm != true || !mounted) return;

    final token = context.read<AuthProvider>().user?.token;
    if (token == null) return;

    AppGradientSpinner.showOverlay(context, message: 'Registrando llegada...');
    final response = await context.read<ViajesProvider>().marcarLlegadaParadero(
      idParadero: paradero.idParadero,
      token: token,
    );

    if (!mounted) return;
    AppGradientSpinner.hideOverlay(context);

    if (response != null) {
      _mostrarConfirmacionLlegada(response);
    } else {
      AppToast.show(context, message: context.read<ViajesProvider>().error ?? 'Error', type: ToastType.error);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _mostrarConfirmacionLlegada(LlegadaParaderoResponse response) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mintLight.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppColors.mintDarker, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Llegada registrada!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              response.nombreParadero,
              style: TextStyle(fontSize: 16, color: AppColors.blueLight, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navyDark.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    value: '${response.paraderosVisitados}/${response.totalParaderos}',
                    label: 'Paraderos',
                  ),
                  Container(width: 1, height: 40, color: AppColors.navyDark.withOpacity(0.1)),
                  _StatItem(
                    value: '${response.progresoViaje.toStringAsFixed(0)}%',
                    label: 'Progreso',
                    valueColor: AppColors.mintDarker,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(backgroundColor: AppColors.blueLight),
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatItem({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.navyDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
