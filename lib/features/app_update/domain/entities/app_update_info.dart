/// Entidad que representa la información de una actualización disponible
class AppUpdateInfo {
  final int idLanzamiento;
  final int idAplicacion;
  final String nombreAplicacion;
  final String version;
  final String estado;
  final DateTime? fechaLanzamiento;
  final String notasVersion;
  final String urlDescarga;
  final int? tamanoArchivo;
  final bool esCritico;
  final int? idGrupo;
  final String? nombreGrupo;
  final DateTime? fechaDisponibilidad;
  final DateTime? fechaFinDisponibilidad;

  const AppUpdateInfo({
    required this.idLanzamiento,
    required this.idAplicacion,
    required this.nombreAplicacion,
    required this.version,
    required this.estado,
    this.fechaLanzamiento,
    required this.notasVersion,
    required this.urlDescarga,
    this.tamanoArchivo,
    required this.esCritico,
    this.idGrupo,
    this.nombreGrupo,
    this.fechaDisponibilidad,
    this.fechaFinDisponibilidad,
  });

  /// Verifica si la actualización está activa (disponible)
  bool get isActive {
    final now = DateTime.now();
    
    // Verificar si estamos dentro del rango de disponibilidad
    if (fechaDisponibilidad != null && now.isBefore(fechaDisponibilidad!)) {
      return false;
    }
    
    if (fechaFinDisponibilidad != null && now.isAfter(fechaFinDisponibilidad!)) {
      return false;
    }
    
    // Solo lanzamientos en estado "activo" o "publicado"
    return estado.toLowerCase() == 'activo' || estado.toLowerCase() == 'publicado';
  }

  /// Obtiene el tamaño del archivo formateado
  String get tamanoFormateado {
    if (tamanoArchivo == null) return 'Tamaño desconocido';
    
    final kb = tamanoArchivo! / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

