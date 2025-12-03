import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_loading_spinner.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../domain/entities/viaje.dart';
import '../bloc/viajes_provider.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final ScrollController _scrollController = ScrollController();
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarHistorial();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMas();
    }
  }

  Future<void> _cargarHistorial() async {
    final authProvider = context.read<AuthProvider>();
    final viajesProvider = context.read<ViajesProvider>();
    final token = authProvider.user?.token;

    if (token != null) {
      _page = 0;
      _hasMore = true;
      await viajesProvider.cargarHistorial(token: token, page: _page);
    }
  }

  Future<void> _cargarMas() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final authProvider = context.read<AuthProvider>();
    final viajesProvider = context.read<ViajesProvider>();
    final token = authProvider.user?.token;

    if (token != null) {
      _page++;
      final nuevosViajes = await viajesProvider.cargarHistorial(
        token: token,
        page: _page,
        append: true,
      );
      
      if (nuevosViajes < 20) {
        _hasMore = false;
      }
    }

    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final viajesProvider = context.watch<ViajesProvider>();
    final historial = viajesProvider.historial;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarHistorial,
          ),
        ],
      ),
      body: viajesProvider.isLoading && historial.isEmpty
          ? const Center(child: AppGradientSpinner())
          : historial.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: historial.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == historial.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildHistorialCard(historial[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistorialCard(Viaje viaje) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha y duración
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      viaje.fechaInicioReal != null
                          ? dateFormat.format(viaje.fechaInicioReal!)
                          : dateFormat.format(viaje.fechaInicioProgramada),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (viaje.fechaInicioReal != null && viaje.fechaFinReal != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _calcularDuracion(viaje.fechaInicioReal!, viaje.fechaFinReal!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
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

            // Bus
            Row(
              children: [
                Icon(Icons.directions_bus, color: AppColors.blueLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bus: ${viaje.placaBus}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Horarios
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.mintDarker, size: 20),
                const SizedBox(width: 8),
                Text(
                  viaje.fechaInicioReal != null && viaje.fechaFinReal != null
                      ? '${timeFormat.format(viaje.fechaInicioReal!)} - ${timeFormat.format(viaje.fechaFinReal!)}'
                      : '${timeFormat.format(viaje.fechaInicioProgramada)} - ${timeFormat.format(viaje.fechaFinProgramada)}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calcularDuracion(DateTime inicio, DateTime fin) {
    final duracion = fin.difference(inicio);
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes % 60;
    
    if (horas > 0) {
      return '${horas}h ${minutos}m';
    }
    return '${minutos}m';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay viajes en el historial',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa viajes para verlos aquí',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

