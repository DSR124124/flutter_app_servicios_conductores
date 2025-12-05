import '../../domain/entities/viaje.dart';

class ViajeModel extends Viaje {
  const ViajeModel({
    required super.idViaje,
    required super.idRuta,
    required super.nombreRuta,
    required super.idBus,
    required super.placaBus,
    super.modeloBus,
    required super.fechaInicioProgramada,
    required super.fechaFinProgramada,
    super.fechaInicioReal,
    super.fechaFinReal,
    required super.estado,
    super.paraderos,
  });

  factory ViajeModel.fromJson(Map<String, dynamic> json) {
    final paraderosJson = json['paraderos'] as List<dynamic>? ?? [];
    
    return ViajeModel(
      idViaje: json['idViaje'] as int? ?? 0,
      idRuta: json['idRuta'] as int? ?? 0,
      nombreRuta: json['nombreRuta'] as String? ?? 
                  json['ruta']?['nombre'] as String? ?? 'Sin nombre',
      idBus: json['idBus'] as int? ?? 0,
      // Manejar ambos formatos: busPlaca/busModelo (backend) y placaBus/modeloBus (alternativo)
      placaBus: json['busPlaca'] as String? ?? 
                json['placaBus'] as String? ?? 
                json['bus']?['placa'] as String? ?? '',
      modeloBus: json['busModelo'] as String? ?? 
                 json['modeloBus'] as String? ?? 
                 json['bus']?['modelo'] as String?,
      fechaInicioProgramada: _parseDateTime(json['fechaInicioProgramada']),
      fechaFinProgramada: _parseDateTime(json['fechaFinProgramada']),
      fechaInicioReal: json['fechaInicioReal'] != null 
          ? _parseDateTime(json['fechaInicioReal']) 
          : null,
      fechaFinReal: json['fechaFinReal'] != null 
          ? _parseDateTime(json['fechaFinReal']) 
          : null,
      estado: json['estado'] as String? ?? 'programado',
      paraderos: paraderosJson
          .map((p) => ParaderoModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'idViaje': idViaje,
      'idRuta': idRuta,
      'nombreRuta': nombreRuta,
      'idBus': idBus,
      'placaBus': placaBus,
      'modeloBus': modeloBus,
      'fechaInicioProgramada': fechaInicioProgramada.toIso8601String(),
      'fechaFinProgramada': fechaFinProgramada.toIso8601String(),
      'fechaInicioReal': fechaInicioReal?.toIso8601String(),
      'fechaFinReal': fechaFinReal?.toIso8601String(),
      'estado': estado,
    };
  }
}

class ParaderoModel extends Paradero {
  const ParaderoModel({
    required super.idParadero,
    required super.nombre,
    required super.latitud,
    required super.longitud,
    required super.orden,
    super.horaLlegadaEstimada,
    super.horaLlegadaReal,
    super.visitado,
    super.estadoParadero,
  });

  factory ParaderoModel.fromJson(Map<String, dynamic> json) {
    // Determinar el estado del paradero
    String estadoParadero = json['estadoParadero'] as String? ?? 'pendiente';
    
    // Si tiene campo visitado pero no estadoParadero, inferir el estado
    final bool visitado = json['visitado'] as bool? ?? 
                          estadoParadero == 'visitado';
    
    return ParaderoModel(
      idParadero: json['idParadero'] as int? ?? json['idPunto'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? 'Paradero',
      latitud: (json['latitud'] as num?)?.toDouble() ?? 
               (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 
                (json['longitude'] as num?)?.toDouble() ?? 0.0,
      orden: json['orden'] as int? ?? 0,
      horaLlegadaEstimada: json['horaLlegadaEstimada'] != null
          ? DateTime.tryParse(json['horaLlegadaEstimada'] as String)
          : null,
      horaLlegadaReal: json['horaLlegadaReal'] != null
          ? DateTime.tryParse(json['horaLlegadaReal'] as String)
          : null,
      visitado: visitado,
      estadoParadero: estadoParadero,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idParadero': idParadero,
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      'orden': orden,
      'visitado': visitado,
      'estadoParadero': estadoParadero,
    };
  }
  
  /// Crea una copia del paradero marcado como visitado
  ParaderoModel copyWithVisitado() {
    return ParaderoModel(
      idParadero: idParadero,
      nombre: nombre,
      latitud: latitud,
      longitud: longitud,
      orden: orden,
      horaLlegadaEstimada: horaLlegadaEstimada,
      horaLlegadaReal: DateTime.now(),
      visitado: true,
      estadoParadero: 'visitado',
    );
  }
}

