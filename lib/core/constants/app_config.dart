class AppConfig {
  AppConfig._();

  static const String backendGestionBaseUrl =
      'https://edugen.brianuceda.xyz/gestion';
  
  static const String backendServiciosBaseUrl =
      'https://edugen.brianuceda.xyz/servicios';

  static const String loginEndpoint = '/api/auth/login';
  
  /// Endpoint para verificar actualizaciones disponibles
  static const String updateCheckEndpoint = '/api/verificar-actualizacion';
  
  /// Código único de identificación de la aplicación para conductores
  static const String appCode = 'FLUTTER_APP_CONDUCTORES';
  
  /// Versión actual de la aplicación
  static const String appVersion = '1.0.0';
}

