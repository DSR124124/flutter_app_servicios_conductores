import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/bloc/auth_provider.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'package:http/http.dart' as http;
import '../../features/notificaciones/data/datasources/notificaciones_remote_data_source.dart';
import '../../features/notificaciones/data/repositories/notificaciones_repository_impl.dart';
import '../../features/notificaciones/domain/usecases/get_mis_notificaciones_usecase.dart';
import '../../features/notificaciones/domain/usecases/marcar_notificacion_leida_usecase.dart';
import '../../features/notificaciones/domain/usecases/crear_notificacion_usecase.dart';
import '../../features/notificaciones/presentation/bloc/notificaciones_provider.dart';
import '../../features/notificaciones/presentation/pages/notificaciones_page.dart';
import '../../features/notificaciones/presentation/pages/crear_notificacion_page.dart';
import '../../features/viajes/data/repositories/viaje_repository_impl.dart';
import '../../features/viajes/domain/usecases/get_mis_viajes_usecase.dart';
import '../../features/viajes/domain/usecases/get_viaje_activo_usecase.dart';
import '../../features/viajes/domain/usecases/iniciar_viaje_usecase.dart';
import '../../features/viajes/domain/usecases/finalizar_viaje_usecase.dart';
import '../../features/viajes/domain/usecases/enviar_ubicacion_usecase.dart';
import '../../features/viajes/presentation/bloc/viajes_provider.dart';
import '../../features/viajes/presentation/pages/estadisticas_page.dart';
import '../../features/viajes/presentation/pages/historial_page.dart';
import '../../features/viajes/presentation/pages/mis_viajes_page.dart';
import '../../features/viajes/presentation/pages/viaje_activo_page.dart';

/// Configuración de rutas de la aplicación usando go_router
class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';

        // Si no está autenticado y no está en login, redirigir a login
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        // Si está autenticado y está en login, redirigir a home
        if (isAuthenticated && isLoginRoute) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/notificaciones',
          name: 'notificaciones',
          builder: (context, state) => _wrapWithNotificacionesProvider(
            NotificacionesPage(
              initialNotificacionId: state.extra is int ? state.extra as int : null,
            ),
          ),
        ),
        GoRoute(
          path: '/notificaciones/nueva',
          name: 'notificacion-nueva',
          builder: (context, state) => const CrearNotificacionPage(),
        ),
        GoRoute(
          path: '/mis-viajes',
          name: 'mis-viajes',
          builder: (context, state) => _wrapWithViajesProvider(const MisViajesPage()),
        ),
        GoRoute(
          path: '/viaje-activo',
          name: 'viaje-activo',
          builder: (context, state) => _wrapWithViajesProvider(const ViajeActivoPage()),
        ),
        GoRoute(
          path: '/historial',
          name: 'historial',
          builder: (context, state) => _wrapWithViajesProvider(const HistorialPage()),
        ),
        GoRoute(
          path: '/estadisticas',
          name: 'estadisticas',
          builder: (context, state) => _wrapWithViajesProvider(const EstadisticasPage()),
        ),
        GoRoute(
          path: '/',
          redirect: (_, __) => '/home',
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Página no encontrada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.matchedLocation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Ir a Inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static GoRouter? _router;

  static GoRouter get router {
    if (_router == null) {
      throw StateError(
        'Router no inicializado. Use AppRouter.createRouter() primero.',
      );
    }
    return _router!;
  }

  static void initialize(AuthProvider authProvider) {
    _router = createRouter(authProvider);
  }

  /// Wrappea un widget con el ViajesProvider
  static Widget _wrapWithViajesProvider(Widget child) {
    final repository = ViajeRepositoryImpl();
    return ChangeNotifierProvider(
      create: (_) => ViajesProvider(
        getMisViajesUseCase: GetMisViajesUseCase(repository),
        getViajeActivoUseCase: GetViajeActivoUseCase(repository),
        iniciarViajeUseCase: IniciarViajeUseCase(repository),
        finalizarViajeUseCase: FinalizarViajeUseCase(repository),
        enviarUbicacionUseCase: EnviarUbicacionUseCase(repository),
      ),
      child: child,
    );
  }

  /// Wrappea un widget con el NotificacionesProvider
  static Widget _wrapWithNotificacionesProvider(Widget child) {
    final remoteDataSource = NotificacionesRemoteDataSourceImpl(
      client: http.Client(),
    );
    final repository =
        NotificacionesRepositoryImpl(remoteDataSource: remoteDataSource);
    final getMisNotificacionesUseCase = GetMisNotificacionesUseCase(repository);
    final marcarLeidaUseCase = MarcarNotificacionLeidaUseCase(repository);

    return ChangeNotifierProvider(
      create: (context) {
        final authRepository = context.read<AuthProvider>().repository;
        return NotificacionesProvider(
          getMisNotificacionesUseCase: getMisNotificacionesUseCase,
          getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
          marcarNotificacionLeidaUseCase: marcarLeidaUseCase,
        );
      },
      child: child,
    );
  }
}
