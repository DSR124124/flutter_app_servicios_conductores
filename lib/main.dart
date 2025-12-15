import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_provider.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/notificaciones/data/datasources/notificaciones_remote_data_source.dart';
import 'features/notificaciones/data/repositories/notificaciones_repository_impl.dart';
import 'features/notificaciones/domain/usecases/get_mis_notificaciones_usecase.dart';
import 'features/notificaciones/domain/usecases/marcar_notificacion_leida_usecase.dart';
import 'features/notificaciones/presentation/bloc/notificaciones_provider.dart';
import 'core/services/notificaciones_background_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;
      if (payload != null) {
        final id = int.tryParse(payload);
        // Navegar a la pantalla de notificaciones, opcionalmente con el ID
        if (id != null) {
          AppRouter.router.push('/notificaciones', extra: id);
        } else {
          AppRouter.router.push('/notificaciones');
        }
      } else {
        AppRouter.router.push('/notificaciones');
      }
    },
  );

  const androidChannel = AndroidNotificationChannel(
    'nett_notif_channel',
    'Notificaciones Nettalco',
    description: 'Notificaciones de la app Nettalco Conductores',
    importance: Importance.high,
  );

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(androidChannel);
}

Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el locale español para DateFormat
  await initializeDateFormatting('es_ES', null);

  // Pedir permiso para notificaciones (Android 13+)
  await _requestNotificationPermission();

  await _initLocalNotifications();

  // Iniciar servicio en segundo plano para WebSocket de notificaciones
  await initializeNotificacionesBackgroundService();

  runApp(const NettalcoConductoresApp());
}

class NettalcoConductoresApp extends StatelessWidget {
  const NettalcoConductoresApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider();
    AppRouter.initialize(authProvider);

    // Configurar dependencias de notificaciones
    final remoteDataSource = NotificacionesRemoteDataSourceImpl(
      client: http.Client(),
    );
    final notifRepository =
        NotificacionesRepositoryImpl(remoteDataSource: remoteDataSource);
    final getMisNotificacionesUseCase =
        GetMisNotificacionesUseCase(notifRepository);
    final marcarLeidaUseCase =
        MarcarNotificacionLeidaUseCase(notifRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<NotificacionesProvider>(
          create: (context) {
            final authRepo = authProvider.repository;
            return NotificacionesProvider(
              getMisNotificacionesUseCase: getMisNotificacionesUseCase,
              getCurrentUserUseCase: GetCurrentUserUseCase(authRepo),
              marcarNotificacionLeidaUseCase: marcarLeidaUseCase,
            );
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Nettalco Conductores',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
