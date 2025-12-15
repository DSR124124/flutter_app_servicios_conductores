class CrearNotificacionDto {
  final String titulo;
  final String mensaje;
  final String tipoNotificacion;
  final String prioridad;
  final int idAplicacion;
  final int creadoPor;
  final bool requiereConfirmacion;
  final bool mostrarComoRecordatorio;
  final List<int> idUsuarios;

  const CrearNotificacionDto({
    required this.titulo,
    required this.mensaje,
    required this.tipoNotificacion,
    required this.prioridad,
    required this.idAplicacion,
    required this.creadoPor,
    required this.requiereConfirmacion,
    required this.mostrarComoRecordatorio,
    required this.idUsuarios,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'mensaje': mensaje,
      'tipoNotificacion': tipoNotificacion,
      'prioridad': prioridad,
      'idAplicacion': idAplicacion,
      'creadoPor': creadoPor,
      'requiereConfirmacion': requiereConfirmacion,
      'mostrarComoRecordatorio': mostrarComoRecordatorio,
      'activo': true,
      'idUsuarios': idUsuarios,
      // 'fechaEnvio': null, // opcional: programar envío
      // 'datosAdicionales': null, // opcional
    };
  }
}


