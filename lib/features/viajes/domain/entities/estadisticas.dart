/// Entidad que representa las estadísticas del conductor
class EstadisticasConductor {
  final int totalViajes;
  final int viajesCompletados;
  final int viajesCancelados;
  final int viajesEnCurso;
  final int viajesProgramados;
  final int totalMinutosConducidos;
  final double promedioMinutosPorViaje;
  final int viajesEsteMes;
  final int minutosEsteMes;
  final int viajesEstaSemana;
  final int minutosEstaSemana;
  final int viajesHoy;
  final int minutosHoy;

  const EstadisticasConductor({
    required this.totalViajes,
    required this.viajesCompletados,
    required this.viajesCancelados,
    required this.viajesEnCurso,
    required this.viajesProgramados,
    required this.totalMinutosConducidos,
    required this.promedioMinutosPorViaje,
    required this.viajesEsteMes,
    required this.minutosEsteMes,
    required this.viajesEstaSemana,
    required this.minutosEstaSemana,
    required this.viajesHoy,
    required this.minutosHoy,
  });

  /// Formatea los minutos a horas y minutos
  String formatearTiempo(int minutos) {
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    if (horas > 0) {
      return '${horas}h ${mins}m';
    }
    return '${mins}m';
  }

  String get tiempoTotalFormateado => formatearTiempo(totalMinutosConducidos);
  String get tiempoEsteMesFormateado => formatearTiempo(minutosEsteMes);
  String get tiempoEstaSemanaFormateado => formatearTiempo(minutosEstaSemana);
  String get tiempoHoyFormateado => formatearTiempo(minutosHoy);
  String get promedioFormateado => formatearTiempo(promedioMinutosPorViaje.round());

  factory EstadisticasConductor.fromJson(Map<String, dynamic> json) {
    return EstadisticasConductor(
      totalViajes: json['totalViajes'] as int? ?? 0,
      viajesCompletados: json['viajesCompletados'] as int? ?? 0,
      viajesCancelados: json['viajesCancelados'] as int? ?? 0,
      viajesEnCurso: json['viajesEnCurso'] as int? ?? 0,
      viajesProgramados: json['viajesProgramados'] as int? ?? 0,
      totalMinutosConducidos: (json['totalMinutosConducidos'] as num?)?.toInt() ?? 0,
      promedioMinutosPorViaje: (json['promedioMinutosPorViaje'] as num?)?.toDouble() ?? 0.0,
      viajesEsteMes: json['viajesEsteMes'] as int? ?? 0,
      minutosEsteMes: (json['minutosEsteMes'] as num?)?.toInt() ?? 0,
      viajesEstaSemana: json['viajesEstaSemana'] as int? ?? 0,
      minutosEstaSemana: (json['minutosEstaSemana'] as num?)?.toInt() ?? 0,
      viajesHoy: json['viajesHoy'] as int? ?? 0,
      minutosHoy: (json['minutosHoy'] as num?)?.toInt() ?? 0,
    );
  }
}

