class PerfilInfo {
  // IDs internos - NO se muestran al usuario
  final int idUsuario;
  final int idRol;
  
  // Datos visibles al usuario
  final String username;
  final String email;
  final String nombreCompleto;
  final String nombreRol;
  final String? fechaUltimoAcceso;

  const PerfilInfo({
    required this.idUsuario,
    required this.idRol,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    required this.nombreRol,
    this.fechaUltimoAcceso,
  });

  factory PerfilInfo.fromMap(Map<String, dynamic> map) {
    return PerfilInfo(
      idUsuario: map['idUsuario'] as int? ?? 0,
      idRol: map['idRol'] as int? ?? 0,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      nombreCompleto: map['nombreCompleto'] as String? ?? '',
      nombreRol: map['nombreRol'] as String? ?? '',
      fechaUltimoAcceso: map['fechaUltimoAcceso'] as String?,
    );
  }
}

