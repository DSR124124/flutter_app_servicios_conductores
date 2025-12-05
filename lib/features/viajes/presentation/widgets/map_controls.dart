import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Controles del mapa (centrar, ver ruta)
class MapControls extends StatelessWidget {
  final bool followMode;
  final VoidCallback onCenterLocation;
  final VoidCallback onShowRoute;

  const MapControls({
    super.key,
    required this.followMode,
    required this.onCenterLocation,
    required this.onShowRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapButton(
          icon: Icons.my_location,
          isActive: followMode,
          onPressed: onCenterLocation,
        ),
        const SizedBox(height: 8),
        _MapButton(
          icon: Icons.route,
          onPressed: onShowRoute,
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const _MapButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
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
}
