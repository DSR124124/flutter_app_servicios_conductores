/// Entidad que representa una ubicación GPS a enviar al servidor
class UbicacionGPS {
  final int idViaje;
  final double latitud;
  final double longitud;
  final double? velocidadKmh;
  final double? rumbo;
  final DateTime timestamp;

  const UbicacionGPS({
    required this.idViaje,
    required this.latitud,
    required this.longitud,
    this.velocidadKmh,
    this.rumbo,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'idViaje': idViaje,
      'latitud': latitud,
      'longitud': longitud,
      if (velocidadKmh != null) 'velocidadKmh': velocidadKmh,
      if (rumbo != null) 'rumbo': rumbo,
    };
  }
}

