import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../domain/entities/viaje.dart';
import '../bloc/viajes_provider.dart';

class MisViajesPage extends StatefulWidget {
  const MisViajesPage({super.key});

  @override
  State<MisViajesPage> createState() => _MisViajesPageState();
}

class _MisViajesPageState extends State<MisViajesPage> {
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarViajes();
    });
  }

  Future<void> _cargarViajes() async {
    final authProvider = context.read<AuthProvider>();
    final viajesProvider = context.read<ViajesProvider>();
    final token = authProvider.user?.token;

    if (token != null) {
      await viajesProvider.cargarViajes(token: token, fecha: _fechaSeleccionada);
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
      _cargarViajes();
    }
  }

  Future<void> _iniciarViaje(Viaje viaje) async {
    final authProvider = context.read<AuthProvider>();
    final viajesProvider = context.read<ViajesProvider>();
    final token = authProvider.user?.token;

    if (token == null) return;

    AppGradientSpinner.showOverlay(context, message: 'Iniciando viaje...');

    final success = await viajesProvider.iniciarViaje(
      idViaje: viaje.idViaje,
      token: token,
    );

    if (!mounted) return;
    AppGradientSpinner.hideOverlay(context);

    if (success) {
      AppToast.show(context, message: '¡Viaje iniciado!', type: ToastType.success);
      context.push('/viaje-activo');
    } else {
      AppToast.show(
        context,
        message: viajesProvider.error ?? 'Error al iniciar viaje',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viajesProvider = context.watch<ViajesProvider>();
    final dateFormat = DateFormat('EEEE, d MMM yyyy', 'es_ES');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Viajes'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarViajes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de fecha
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: InkWell(
              onTap: _seleccionarFecha,
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dateFormat.format(_fechaSeleccionada),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Viaje activo (si existe)
          if (viajesProvider.tieneViajeActivo) ...[
            _buildViajeActivoBanner(viajesProvider.viajeActivo!),
            const Divider(height: 1),
          ],

          // Lista de viajes
          Expanded(
            child: viajesProvider.isLoading
                ? const Center(child: AppGradientSpinner())
                : viajesProvider.viajes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _cargarViajes,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: viajesProvider.viajes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final viaje = viajesProvider.viajes[index];
                            return _buildViajeCard(viaje);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildViajeActivoBanner(Viaje viaje) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.success.withOpacity(0.1),
      child: InkWell(
        onTap: () => context.push('/viaje-activo'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIAJE EN CURSO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    viaje.nombreRuta,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildViajeCard(Viaje viaje) {
    final timeFormat = DateFormat('HH:mm');
    final bool puedeIniciar = viaje.esProgramado && !context.read<ViajesProvider>().tieneViajeActivo;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorEstado(viaje.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    viaje.estadoFormateado,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getColorEstado(viaje.estado),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${timeFormat.format(viaje.fechaInicioProgramada)} - ${timeFormat.format(viaje.fechaFinProgramada)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nombre de ruta
            Row(
              children: [
                Icon(Icons.route, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viaje.nombreRuta,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Info del bus
            Row(
              children: [
                Icon(Icons.directions_bus, color: AppColors.blueLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bus: ${viaje.placaBus}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (viaje.modeloBus != null) ...[
                  Text(
                    ' • ${viaje.modeloBus}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),

            if (viaje.paraderos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.mintDarker, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${viaje.paraderos.length} paraderos',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            // Botón de iniciar
            if (puedeIniciar) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _iniciarViaje(viaje),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('INICIAR VIAJE'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay viajes programados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona otra fecha o espera a que te asignen viajes',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'programado':
        return AppColors.blueLight;
      case 'en_curso':
        return AppColors.success;
      case 'completado':
        return AppColors.mintDarker;
      case 'cancelado':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

