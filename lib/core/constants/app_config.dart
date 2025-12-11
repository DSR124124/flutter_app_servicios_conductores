class AppConfig {
  AppConfig._();

  static const String backendGestionBaseUrl =
      'https://edugen.brianuceda.xyz/gestion';
  
  static const String backendServiciosBaseUrl =
      'https://edugen.brianuceda.xyz/servicios';

  static const String loginEndpoint = '/api/auth/login';
  
  /// Endpoint para verificar actualizaciones disponibles
  /// Formato: /api/verificar-actualizacion/{idUsuario}/{codigoProducto}/{versionActual}
  static const String updateCheckEndpoint = '/api/verificar-actualizacion';
  
  /// Código único de identificación de la aplicación para conductores
  /// Este código debe coincidir con el codigoProducto registrado en la tabla aplicaciones
  /// del backend-gestion. Debe ser único y no cambiar una vez registrado.
  static const String appCode = 'FLUTTER_APP_CONDUCTORES';
  
  /// Versión actual de la aplicación (debe coincidir con pubspec.yaml)
  /// NOTA: Esta constante solo se usa como fallback. La versión real se obtiene de PackageInfo
  static const String appVersion = '1.0.1';
  
  /// Endpoint para obtener la versión actual de la app desde la BD
  /// Formato: /api/version-app/{codigoProducto}
  static const String versionAppEndpoint = '/api/version-app';
}

