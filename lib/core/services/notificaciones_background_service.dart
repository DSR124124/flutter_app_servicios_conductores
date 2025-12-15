import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/notificaciones/data/datasources/notificaciones_ws_service.dart';
import '../../features/notificaciones/domain/entities/notificacion.dart';

/// Inicializa el servicio de fondo que mantiene el WebSocket de notificaciones.
Future<void> initializeNotificacionesBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStartNotificacionesService,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'nett_notif_channel',
      initialNotificationTitle: 'Nettalco Conductores',
      initialNotificationContent: 'Escuchando notificaciones...',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStartNotificacionesService,
      onBackground: _onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
bool _onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// Punto de entrada del isolate de background.
@pragma('vm:entry-point')
void onStartNotificacionesService(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  final FlutterLocalNotificationsPlugin localPlugin =
      FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await localPlugin.initialize(initSettings);

  const androidChannel = AndroidNotificationChannel(
    'nett_notif_channel',
    'Notificaciones Nettalco',
    description: 'Notificaciones de la app Nettalco Conductores',
    importance: Importance.high,
  );

  final androidSpecific =
      localPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidSpecific?.createNotificationChannel(androidChannel);

  // Conexión WebSocket a tu backend
  final wsService = NotificacionesWsService();

  // Leer usuario/cache de auth para obtener el token JWT
  final authLocal = AuthLocalDataSource();
  final cachedUser = await authLocal.getCachedUser();
  final token = cachedUser?.token;

  if (token == null || token.isEmpty) {
    // Sin token no podemos suscribir por usuario.
    return;
  }

  wsService.conectar(
    token: token,
    onNueva: (Notificacion n) async {
      final String enviadoPor =
          n.creadorNombre ?? n.nombreAplicacion ?? 'Nettalco Conductores';
      final String previewMensaje =
          n.mensaje.length > 80 ? '${n.mensaje.substring(0, 80)}...' : n.mensaje;

      final androidDetails = AndroidNotificationDetails(
        'nett_notif_channel',
        'Notificaciones Nettalco',
        channelDescription: 'Notificaciones de la app Nettalco Conductores',
        importance: Importance.high,
        priority: Priority.high,
        // Icono pequeño de la app
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          '$previewMensaje\n\nEnviado por $enviadoPor',
          contentTitle: n.titulo,
        ),
      );

      final details = NotificationDetails(android: androidDetails);

      await localPlugin.show(
        n.idNotificacion ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        n.titulo,
        n.mensaje,
        details,
        payload: n.idNotificacion.toString(),
      );
    },
  );
}


