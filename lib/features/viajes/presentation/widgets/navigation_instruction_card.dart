import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/services/directions_service.dart';

/// Widget que muestra la instrucción de navegación actual
class NavigationInstructionCard extends StatelessWidget {
  final NavigationInstruction? instruction;
  final int? totalDistance;
  final int? totalDuration;

  const NavigationInstructionCard({
    super.key,
    this.instruction,
    this.totalDistance,
    this.totalDuration,
  });

  @override
  Widget build(BuildContext context) {
    if (instruction == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de maniobra
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blueLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getManeuverIcon(instruction!.maneuver),
              color: AppColors.blueLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Instrucción y distancia
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction!.instruction,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(instruction!.distance),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (instruction!.duration > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(instruction!.duration),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getManeuverIcon(String? maneuver) {
    if (maneuver == null) return Icons.navigation;
    
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
      case 'turn-sharp-left':
        return Icons.turn_left;
      case 'turn-right':
      case 'turn-sharp-right':
        return Icons.turn_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'straight':
        return Icons.straight;
      case 'ramp-left':
        return Icons.merge;
      case 'ramp-right':
        return Icons.merge;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      case 'ferry':
        return Icons.directions_boat;
      default:
        return Icons.navigation;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      return '$minutes min';
    }
  }
}
