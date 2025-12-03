import '../entities/perfil_info.dart';

abstract class PerfilRepository {
  Future<PerfilInfo> obtenerPerfil();
}

