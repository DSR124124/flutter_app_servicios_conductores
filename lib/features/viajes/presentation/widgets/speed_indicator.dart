import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../config/theme/app_colors.dart';

/// Indicador de velocidad del vehículo
class SpeedIndicator extends StatelessWidget {
  final Position position;

  const SpeedIndicator({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final speedKmh = (position.speed * 3.6).toStringAsFixed(0);
    
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            speedKmh,
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
            ),
          ),
        ],
      ),
    );
  }
}
