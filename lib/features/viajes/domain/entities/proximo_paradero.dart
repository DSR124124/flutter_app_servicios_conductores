/// Entidad que representa el próximo paradero a visitar en la navegación.
/// Se usa para guiar al conductor en orden secuencial.
class ProximoParadero {
  final int idViaje;
  final int? idParadero;
  final int? ordenParadero;
  final String? nombreParadero;
  final double? latitud;
  final double? longitud;
  final int paraderosVisitados;
  final int totalParaderos;
  final bool todosVisitados;
  final String mensaje;

  const ProximoParadero({
    required this.idViaje,
    this.idParadero,
    this.ordenParadero,
    this.nombreParadero,
    this.latitud,
    this.longitud,
    required this.paraderosVisitados,
    required this.totalParaderos,
    required this.todosVisitados,
    required this.mensaje,
  });

  factory ProximoParadero.fromJson(Map<String, dynamic> json) {
    return ProximoParadero(
      idViaje: json['idViaje'] as int,
      idParadero: json['idParadero'] as int?,
      ordenParadero: json['ordenParadero'] as int?,
      nombreParadero: json['nombreParadero'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      paraderosVisitados: json['paraderosVisitados'] as int? ?? 0,
      totalParaderos: json['totalParaderos'] as int? ?? 0,
      todosVisitados: json['todosVisitados'] as bool? ?? false,
      mensaje: json['mensaje'] as String? ?? '',
    );
  }

  /// Calcula el progreso del viaje en porcentaje
  double get progresoViaje {
    if (totalParaderos == 0) return 0.0;
    return (paraderosVisitados / totalParaderos) * 100;
  }

  /// Indica si hay un paradero pendiente
  bool get hayParaderoPendiente => idParadero != null && !todosVisitados;
}
