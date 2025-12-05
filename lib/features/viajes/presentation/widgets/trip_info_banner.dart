import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/viaje.dart';

/// Banner superior que muestra info del siguiente paradero
class TripInfoBanner extends StatelessWidget {
  final Paradero paradero;
  final int visitados;
  final int total;

  const TripInfoBanner({
    super.key,
    required this.paradero,
    required this.visitados,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyDark, AppColors.navyDark.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Número de orden
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.mintLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${paradero.orden}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info del paradero
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIGUIENTE PARADERO',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.blueLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  paradero.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$visitados de $total paraderos',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mintLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
