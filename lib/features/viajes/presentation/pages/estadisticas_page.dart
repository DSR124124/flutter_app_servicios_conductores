import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../domain/entities/estadisticas.dart';
import '../bloc/viajes_provider.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEstadisticas();
    });
  }

  Future<void> _cargarEstadisticas() async {
    final authProvider = context.read<AuthProvider>();
    final viajesProvider = context.read<ViajesProvider>();
    final token = authProvider.user?.token;

    if (token != null) {
      await viajesProvider.cargarEstadisticas(token: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viajesProvider = context.watch<ViajesProvider>();
    final estadisticas = viajesProvider.estadisticas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Estadísticas'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEstadisticas,
          ),
        ],
      ),
      body: viajesProvider.isLoading
          ? const Center(child: AppGradientSpinner())
          : estadisticas == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _cargarEstadisticas,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumen principal
                        _buildResumenCard(estadisticas),
                        const SizedBox(height: 16),

                        // Estadísticas por período
                        Text(
                          'Por Período',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPeriodoCard('Hoy', estadisticas.viajesHoy, estadisticas.tiempoHoyFormateado, AppColors.success),
                        const SizedBox(height: 8),
                        _buildPeriodoCard('Esta Semana', estadisticas.viajesEstaSemana, estadisticas.tiempoEstaSemanaFormateado, AppColors.blueLight),
                        const SizedBox(height: 8),
                        _buildPeriodoCard('Este Mes', estadisticas.viajesEsteMes, estadisticas.tiempoEsteMesFormateado, AppColors.primary),
                        const SizedBox(height: 24),

                        // Estados de viajes
                        Text(
                          'Estado de Viajes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEstadosGrid(estadisticas),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildResumenCard(EstadisticasConductor estadisticas) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.blueLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              '${estadisticas.viajesCompletados}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Viajes Completados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tiempo total: ${estadisticas.tiempoTotalFormateado}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Promedio por viaje: ${estadisticas.promedioFormateado}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodoCard(String titulo, int viajes, String tiempo, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.directions_bus, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$viajes viajes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    tiempo,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadosGrid(EstadisticasConductor estadisticas) {
    return Row(
      children: [
        Expanded(child: _buildEstadoItem('Completados', estadisticas.viajesCompletados, AppColors.success, Icons.check_circle)),
        const SizedBox(width: 8),
        Expanded(child: _buildEstadoItem('Programados', estadisticas.viajesProgramados, AppColors.blueLight, Icons.schedule)),
        const SizedBox(width: 8),
        Expanded(child: _buildEstadoItem('En Curso', estadisticas.viajesEnCurso, AppColors.warning, Icons.play_circle)),
        const SizedBox(width: 8),
        Expanded(child: _buildEstadoItem('Cancelados', estadisticas.viajesCancelados, AppColors.error, Icons.cancel)),
      ],
    );
  }

  Widget _buildEstadoItem(String titulo, int cantidad, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$cantidad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Error al cargar estadísticas'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _cargarEstadisticas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

