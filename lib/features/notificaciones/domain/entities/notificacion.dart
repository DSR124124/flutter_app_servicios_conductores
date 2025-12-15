import 'package:equatable/equatable.dart';

class Notificacion extends Equatable {
  final int idNotificacion;
  final String titulo;
  final String mensaje;
  final String tipoNotificacion;
  final String prioridad;
  final String fechaCreacion;
  final String? fechaEnvio;
  final bool requiereConfirmacion;
  final dynamic datosAdicionales;
  final String? nombreAplicacion;
  final String? creadorNombre;
  final bool leida;
  final String? fechaLectura;
  final bool confirmada;
  final String? fechaConfirmacion;

  const Notificacion({
    required this.idNotificacion,
    required this.titulo,
    required this.mensaje,
    required this.tipoNotificacion,
    required this.prioridad,
    required this.fechaCreacion,
    required this.fechaEnvio,
    required this.requiereConfirmacion,
    required this.datosAdicionales,
    required this.nombreAplicacion,
    required this.creadorNombre,
    required this.leida,
    required this.fechaLectura,
    required this.confirmada,
    required this.fechaConfirmacion,
  });

  @override
  List<Object?> get props => [
        idNotificacion,
        titulo,
        mensaje,
        tipoNotificacion,
        prioridad,
        fechaCreacion,
        fechaEnvio,
        requiereConfirmacion,
        datosAdicionales,
        nombreAplicacion,
        creadorNombre,
        leida,
        fechaLectura,
        confirmada,
        fechaConfirmacion,
      ];
}


