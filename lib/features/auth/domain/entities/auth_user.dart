class AuthUser {
  final int idUsuario;
  final String username;
  final String rol;
  final String token;
  final String? email;
  final String? nombreCompleto;
  final int? idRol;
  final String? nombreRol;
  final String? fechaUltimoAcceso;

  const AuthUser({
    required this.idUsuario,
    required this.username,
    required this.rol,
    required this.token,
    this.email,
    this.nombreCompleto,
    this.idRol,
    this.nombreRol,
    this.fechaUltimoAcceso,
  });
}

