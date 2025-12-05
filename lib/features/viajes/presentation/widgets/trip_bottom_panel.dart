import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/viaje.dart';

/// Panel inferior con información del viaje y botones de acción
class TripBottomPanel extends StatelessWidget {
  final Viaje viaje;
  final Paradero? siguienteParadero;
  final bool todosVisitados;
  final VoidCallback? onMarcarLlegada;
  final VoidCallback? onFinalizarViaje;

  const TripBottomPanel({
    super.key,
    required this.viaje,
    this.siguienteParadero,
    required this.todosVisitados,
    this.onMarcarLlegada,
    this.onFinalizarViaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                  _InfoCard(value: viaje.nombreRuta, label: 'Ruta', icon: Icons.route),
                  const SizedBox(width: 12),
                  _InfoCard(value: viaje.placaBus, label: 'Bus', icon: Icons.directions_bus),
                ],
              ),

              const SizedBox(height: 12),

              // Botón MARCAR LLEGADA
              if (siguienteParadero != null && !todosVisitados)
                _MarcarLlegadaButton(
                  paradero: siguienteParadero!,
                  onPressed: onMarcarLlegada,
                ),

              // Botón FINALIZAR VIAJE
              if (todosVisitados) ...[
                const SizedBox(height: 12),
                _FinalizarViajeButton(onPressed: onFinalizarViaje),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _InfoCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.navyDark.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.navyDark, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.navyDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarcarLlegadaButton extends StatelessWidget {
  final Paradero paradero;
  final VoidCallback? onPressed;

  const _MarcarLlegadaButton({required this.paradero, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.location_on),
        label: Column(
          children: [
            const Text(
              'MARCAR LLEGADA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              '#${paradero.orden} - ${paradero.nombre}',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mintDarker,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _FinalizarViajeButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _FinalizarViajeButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.flag_circle),
        label: const Text(
          '¡FINALIZAR VIAJE!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.mintDarker,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
