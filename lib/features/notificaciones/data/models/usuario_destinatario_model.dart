class UsuarioDestinatario {
  final int idUsuario;
  final String nombre;

  UsuarioDestinatario({
    required this.idUsuario,
    required this.nombre,
  });

  factory UsuarioDestinatario.fromJson(Map<String, dynamic> json) {
    final id = json['idUsuario'] as int? ?? 0;
    final nombreCompleto = json['nombreCompleto'] as String?;
    final username = json['username'] as String?;

    return UsuarioDestinatario(
      idUsuario: id,
      nombre: (nombreCompleto?.isNotEmpty == true
              ? nombreCompleto
              : username) ??
          'Usuario $id',
    );
  }
}


