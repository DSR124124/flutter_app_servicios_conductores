/// Entidad que representa un viaje asignado al conductor
class Viaje {
  final int idViaje;
  final int idRuta;
  final String nombreRuta;
  final int idBus;
  final String placaBus;
  final String? modeloBus;
  final DateTime fechaInicioProgramada;
  final DateTime fechaFinProgramada;
  final DateTime? fechaInicioReal;
  final DateTime? fechaFinReal;
  final String estado; // programado, en_curso, completado, cancelado
  final List<Paradero> paraderos;

  const Viaje({
    required this.idViaje,
    required this.idRuta,
    required this.nombreRuta,
    required this.idBus,
    required this.placaBus,
    this.modeloBus,
    required this.fechaInicioProgramada,
    required this.fechaFinProgramada,
    this.fechaInicioReal,
    this.fechaFinReal,
    required this.estado,
    this.paraderos = const [],
  });

  bool get esProgramado => estado == 'programado';
  bool get estaEnCurso => estado == 'en_curso';
  bool get estaCompletado => estado == 'completado';
  bool get estaCancelado => estado == 'cancelado';

  String get estadoFormateado {
    switch (estado) {
      case 'programado':
        return 'Programado';
      case 'en_curso':
        return 'En Curso';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }
}

/// Entidad que representa un paradero/parada de la ruta
class Paradero {
  final int idParadero;
  final String nombre;
  final double latitud;
  final double longitud;
  final int orden;
  final DateTime? horaLlegadaEstimada;
  final DateTime? horaLlegadaReal;
  final bool visitado;

  const Paradero({
    required this.idParadero,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.orden,
    this.horaLlegadaEstimada,
    this.horaLlegadaReal,
    this.visitado = false,
  });
}

