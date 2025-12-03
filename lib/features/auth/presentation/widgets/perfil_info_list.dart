import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/perfil_info.dart';

class PerfilInfoList extends StatelessWidget {
  const PerfilInfoList({super.key, required this.perfil});

  final PerfilInfo perfil;

  @override
  Widget build(BuildContext context) {
    final data = <String, String>{};
    
    if (perfil.nombreCompleto.isNotEmpty) {
      data['Nombre Completo'] = perfil.nombreCompleto;
    }
    if (perfil.username.isNotEmpty) {
      data['Usuario'] = perfil.username;
    }
    if (perfil.email.isNotEmpty) {
      data['Correo Electrónico'] = perfil.email;
    }
    if (perfil.nombreRol.isNotEmpty) {
      data['Rol'] = perfil.nombreRol;
    }
    if (perfil.fechaUltimoAcceso != null && perfil.fechaUltimoAcceso!.isNotEmpty) {
      data['Último Acceso'] = _formatFecha(perfil.fechaUltimoAcceso!);
    }

    if (data.isEmpty) {
      return const Center(
        child: Text('No hay información disponible'),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: bottomPadding > 0 ? bottomPadding + 16 : 16,
      ),
      itemCount: data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final key = data.keys.elementAt(index);
        final value = data[key]!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                _getIconForField(key),
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  IconData _getIconForField(String field) {
    switch (field) {
      case 'Nombre Completo':
        return Icons.person;
      case 'Usuario':
        return Icons.account_circle;
      case 'Correo Electrónico':
        return Icons.email;
      case 'Rol':
        return Icons.work;
      case 'Último Acceso':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }
}

