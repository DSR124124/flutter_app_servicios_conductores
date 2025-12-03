import 'viaje.dart';

/// Entidad que representa el viaje actualmente en curso del conductor
class ViajeActivo {
  final Viaje viaje;
  final double? latitudActual;
  final double? longitudActual;
  final double? velocidadActual;
  final double? rumboActual;
  final int paraderoActualIndex;
  final DateTime? ultimaActualizacion;

  const ViajeActivo({
    required this.viaje,
    this.latitudActual,
    this.longitudActual,
    this.velocidadActual,
    this.rumboActual,
    this.paraderoActualIndex = 0,
    this.ultimaActualizacion,
  });

  Paradero? get paraderoActual {
    if (viaje.paraderos.isEmpty || paraderoActualIndex >= viaje.paraderos.length) {
      return null;
    }
    return viaje.paraderos[paraderoActualIndex];
  }

  Paradero? get proximoParadero {
    final nextIndex = paraderoActualIndex + 1;
    if (viaje.paraderos.isEmpty || nextIndex >= viaje.paraderos.length) {
      return null;
    }
    return viaje.paraderos[nextIndex];
  }

  int get paraderosVisitados {
    return viaje.paraderos.where((p) => p.visitado).length;
  }

  int get totalParaderos => viaje.paraderos.length;

  double get progreso {
    if (totalParaderos == 0) return 0;
    return paraderosVisitados / totalParaderos;
  }
}

