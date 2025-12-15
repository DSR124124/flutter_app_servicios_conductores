import '../../domain/entities/notificacion.dart';

class NotificacionModel extends Notificacion {
  const NotificacionModel({
    required super.idNotificacion,
    required super.titulo,
    required super.mensaje,
    required super.tipoNotificacion,
    required super.prioridad,
    required super.fechaCreacion,
    required super.fechaEnvio,
    required super.requiereConfirmacion,
    required super.datosAdicionales,
    required super.nombreAplicacion,
    required super.creadorNombre,
    required super.leida,
    required super.fechaLectura,
    required super.confirmada,
    required super.fechaConfirmacion,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      idNotificacion: json['idNotificacion'] as int,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipoNotificacion: json['tipoNotificacion'] as String,
      prioridad: json['prioridad'] as String,
      fechaCreacion: json['fechaCreacion'] as String,
      fechaEnvio: json['fechaEnvio'] as String?,
      requiereConfirmacion: json['requiereConfirmacion'] as bool? ?? false,
      datosAdicionales: json['datosAdicionales'],
      nombreAplicacion: json['nombreAplicacion'] as String?,
      creadorNombre: json['creadorNombre'] as String?,
      leida: json['leida'] as bool? ?? false,
      fechaLectura: json['fechaLectura'] as String?,
      confirmada: json['confirmada'] as bool? ?? false,
      fechaConfirmacion: json['fechaConfirmacion'] as String?,
    );
  }
}


