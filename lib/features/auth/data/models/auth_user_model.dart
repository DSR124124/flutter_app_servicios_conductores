import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.idUsuario,
    required super.username,
    required super.rol,
    required super.token,
    super.email,
    super.nombreCompleto,
    super.idRol,
    super.nombreRol,
    super.fechaUltimoAcceso,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final usuarioJson = json['usuario'] as Map<String, dynamic>? ?? json;
    
    return AuthUserModel(
      idUsuario: json['idUsuario'] as int? ?? usuarioJson['idUsuario'] as int? ?? 0,
      username: json['username'] as String? ?? usuarioJson['username'] as String? ?? '',
      rol: json['rol'] as String? ?? usuarioJson['rol'] as String? ?? json['nombreRol'] as String? ?? '',
      token: json['token'] as String? ?? '',
      email: json['email'] as String? ?? usuarioJson['email'] as String?,
      nombreCompleto: json['nombreCompleto'] as String? ?? usuarioJson['nombreCompleto'] as String?,
      idRol: json['idRol'] as int? ?? usuarioJson['idRol'] as int?,
      nombreRol: json['nombreRol'] as String? ?? usuarioJson['nombreRol'] as String?,
      fechaUltimoAcceso: json['fechaUltimoAcceso'] as String? ?? usuarioJson['fechaUltimoAcceso'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'idUsuario': idUsuario,
      'username': username,
      'rol': rol,
      if (email != null) 'email': email,
      if (nombreCompleto != null) 'nombreCompleto': nombreCompleto,
      if (idRol != null) 'idRol': idRol,
      if (nombreRol != null) 'nombreRol': nombreRol,
      if (fechaUltimoAcceso != null) 'fechaUltimoAcceso': fechaUltimoAcceso,
    };
  }
}

