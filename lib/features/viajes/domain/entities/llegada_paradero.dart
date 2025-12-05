/// Entidad que representa la respuesta al marcar llegada a un paradero
class LlegadaParaderoResponse {
  final int idLlegada;
  final int idViaje;
  final int idParadero;
  final int ordenParadero;
  final String nombreParadero;
  final DateTime fechaLlegada;
  final double? latitudLlegada;
  final double? longitudLlegada;
  final int paraderosVisitados;
  final int totalParaderos;
  final bool esUltimoParadero;
  final String mensaje;

  const LlegadaParaderoResponse({
    required this.idLlegada,
    required this.idViaje,
    required this.idParadero,
    required this.ordenParadero,
    required this.nombreParadero,
    required this.fechaLlegada,
    this.latitudLlegada,
    this.longitudLlegada,
    required this.paraderosVisitados,
    required this.totalParaderos,
    required this.esUltimoParadero,
    required this.mensaje,
  });

  factory LlegadaParaderoResponse.fromJson(Map<String, dynamic> json) {
    return LlegadaParaderoResponse(
      idLlegada: json['idLlegada'] as int,
      idViaje: json['idViaje'] as int,
      idParadero: json['idParadero'] as int,
      ordenParadero: json['ordenParadero'] as int,
      nombreParadero: json['nombreParadero'] as String,
      fechaLlegada: DateTime.parse(json['fechaLlegada'] as String),
      latitudLlegada: json['latitudLlegada'] as double?,
      longitudLlegada: json['longitudLlegada'] as double?,
      paraderosVisitados: json['paraderosVisitados'] as int,
      totalParaderos: json['totalParaderos'] as int,
      esUltimoParadero: json['esUltimoParadero'] as bool,
      mensaje: json['mensaje'] as String,
    );
  }

  /// Calcula el progreso del viaje en porcentaje
  double get progresoViaje {
    if (totalParaderos == 0) return 0.0;
    return (paraderosVisitados / totalParaderos) * 100;
  }
}

