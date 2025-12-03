import '../../domain/entities/app_update_info.dart';

/// Modelo de datos para mapear la respuesta del servidor
class AppUpdateModel extends AppUpdateInfo {
  const AppUpdateModel({
    required super.idLanzamiento,
    required super.idAplicacion,
    required super.nombreAplicacion,
    required super.version,
    required super.estado,
    super.fechaLanzamiento,
    required super.notasVersion,
    required super.urlDescarga,
    super.tamanoArchivo,
    required super.esCritico,
    super.idGrupo,
    super.nombreGrupo,
    super.fechaDisponibilidad,
    super.fechaFinDisponibilidad,
  });

  /// Factory para parsear respuesta del endpoint de lista de lanzamientos
  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      idLanzamiento: json['idLanzamiento'] as int,
      idAplicacion: json['idAplicacion'] as int,
      nombreAplicacion: json['nombreAplicacion'] as String? ?? '',
      version: json['version'] as String,
      estado: json['estado'] as String? ?? 'activo',
      fechaLanzamiento: json['fechaLanzamiento'] != null
          ? DateTime.tryParse(json['fechaLanzamiento'] as String)
          : null,
      notasVersion: json['notasVersion'] as String? ?? '',
      urlDescarga: json['urlDescarga'] as String? ?? '',
      tamanoArchivo: json['tamanoArchivo'] as int?,
      esCritico: json['esCritico'] as bool? ?? false,
      idGrupo: json['idGrupo'] as int?,
      nombreGrupo: json['nombreGrupo'] as String?,
      fechaDisponibilidad: json['fechaDisponibilidad'] != null
          ? DateTime.tryParse(json['fechaDisponibilidad'] as String)
          : null,
      fechaFinDisponibilidad: json['fechaFinDisponibilidad'] != null
          ? DateTime.tryParse(json['fechaFinDisponibilidad'] as String)
          : null,
    );
  }

  /// Factory para parsear respuesta del endpoint de verificar actualización
  factory AppUpdateModel.fromVerificarActualizacionJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      idLanzamiento: json['idLanzamiento'] as int? ?? 0,
      idAplicacion: json['idAplicacion'] as int? ?? 0,
      nombreAplicacion: json['nombreAplicacion'] as String? ?? '',
      version: json['versionNueva'] as String? ?? '', // Campo diferente en este endpoint
      estado: json['estado'] as String? ?? 'activo',
      fechaLanzamiento: json['fechaLanzamiento'] != null
          ? DateTime.tryParse(json['fechaLanzamiento'] as String)
          : null,
      notasVersion: json['notasVersion'] as String? ?? '',
      urlDescarga: json['urlDescarga'] as String? ?? '',
      tamanoArchivo: json['tamanoArchivo'] as int?,
      esCritico: json['esCritico'] as bool? ?? false,
      idGrupo: null, // No se incluye en este endpoint
      nombreGrupo: json['nombreGrupo'] as String?,
      fechaDisponibilidad: json['fechaDisponibilidad'] != null
          ? DateTime.tryParse(json['fechaDisponibilidad'] as String)
          : null,
      fechaFinDisponibilidad: json['fechaFinDisponibilidad'] != null
          ? DateTime.tryParse(json['fechaFinDisponibilidad'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idLanzamiento': idLanzamiento,
      'idAplicacion': idAplicacion,
      'nombreAplicacion': nombreAplicacion,
      'version': version,
      'estado': estado,
      'fechaLanzamiento': fechaLanzamiento?.toIso8601String(),
      'notasVersion': notasVersion,
      'urlDescarga': urlDescarga,
      'tamanoArchivo': tamanoArchivo,
      'esCritico': esCritico,
      'idGrupo': idGrupo,
      'nombreGrupo': nombreGrupo,
      'fechaDisponibilidad': fechaDisponibilidad?.toIso8601String(),
      'fechaFinDisponibilidad': fechaFinDisponibilidad?.toIso8601String(),
    };
  }
}

