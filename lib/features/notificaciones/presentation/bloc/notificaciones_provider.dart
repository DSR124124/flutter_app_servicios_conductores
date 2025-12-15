import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/usecases/get_mis_notificaciones_usecase.dart';
import '../../domain/usecases/marcar_notificacion_leida_usecase.dart';
import '../../data/datasources/notificaciones_ws_service.dart';
import '../../../../main.dart';

class NotificacionesProvider extends ChangeNotifier {
  final GetMisNotificacionesUseCase getMisNotificacionesUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final MarcarNotificacionLeidaUseCase marcarNotificacionLeidaUseCase;
  final NotificacionesWsService _wsService = NotificacionesWsService();

  NotificacionesProvider({
    required this.getMisNotificacionesUseCase,
    required this.getCurrentUserUseCase,
    required this.marcarNotificacionLeidaUseCase,
  });

  List<Notificacion> _todas = [];
  List<Notificacion> _filtradas = [];
  bool _isLoading = false;
  String _busqueda = '';
  bool? _filtroLeidas; // null = todas, true = leídas, false = no leídas
  DateTime? _filtroFecha; // solo día

  List<Notificacion> get notificaciones => _filtradas;
  bool get isLoading => _isLoading;
  int get unreadCount =>
      _todas.where((n) => n.leida == false).length;
  bool _disposed = false;

  Future<void> cargarNotificaciones(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await getCurrentUserUseCase();
      if (user == null) {
        try {
          AppToast.show(
            context,
            message: 'No se pudo obtener el usuario actual',
            type: ToastType.error,
          );
        } catch (_) {
          // Context puede ser inválido, ignorar
        }
        return;
      }

      _todas = await getMisNotificacionesUseCase(
        idUsuario: user.idUsuario,
        token: user.token,
      );
      _aplicarFiltros();

      // Conectar WebSocket (solo si no estaba conectado)
      if (!_wsService.isConnected) {
        debugPrint('Conectando WebSocket de notificaciones...');
        _wsService.conectar(
          token: user.token,
          onNueva: (Notificacion n) async {
            debugPrint('Nueva notificación recibida por WebSocket: ${n.titulo}');
            // Añadir a la lista en memoria
            _todas.insert(0, n);
            _aplicarFiltros();

            // Mostrar notificación local en primer plano
            await _mostrarNotificacionLocal(n);
            
            // Notificar a los listeners
            if (!_disposed) {
              notifyListeners();
            }
          },
        );
        debugPrint('WebSocket conectado: ${_wsService.isConnected}');
      } else {
        debugPrint('WebSocket ya estaba conectado');
      }
    } catch (e) {
      try {
        AppToast.show(
          context,
          message: 'Error al cargar notificaciones',
          type: ToastType.error,
        );
      } catch (_) {
        // Context puede ser inválido, ignorar
      }
    } finally {
      _isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _mostrarNotificacionLocal(Notificacion n) async {
    try {
      // Verificar permisos de notificaciones
      final permissionStatus = await Permission.notification.status;
      if (!permissionStatus.isGranted) {
        debugPrint('Permisos de notificaciones no otorgados');
        // Intentar solicitar permisos
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          debugPrint('Usuario rechazó permisos de notificaciones');
          return;
        }
      }

      final String enviadoPor =
          n.creadorNombre ?? n.nombreAplicacion ?? 'Nettalco Conductores';
      final String previewMensaje =
          n.mensaje.length > 80 ? '${n.mensaje.substring(0, 80)}...' : n.mensaje;

      // Usar el ID de la notificación
      final notificationId = n.idNotificacion;

      final androidDetails = AndroidNotificationDetails(
        'nett_notif_channel',
        'Notificaciones Nettalco',
        channelDescription: 'Notificaciones de la app Nettalco Conductores',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          '$previewMensaje\n\nEnviado por $enviadoPor',
          contentTitle: n.titulo,
        ),
        enableVibration: true,
        playSound: true,
      );

      final details = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        n.titulo,
        n.mensaje,
        details,
        payload: notificationId.toString(),
      );
      
      debugPrint('Notificación mostrada: ${n.titulo}');
    } catch (e) {
      debugPrint('Error al mostrar notificación local: $e');
    }
  }

  void actualizarBusqueda(String valor) {
    _busqueda = valor;
    _aplicarFiltros();
  }

  void actualizarFiltroLeidas(bool? soloLeidas) {
    _filtroLeidas = soloLeidas;
    _aplicarFiltros();
  }

  void actualizarFiltroFecha(DateTime? fecha) {
    _filtroFecha = fecha;
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    if (_disposed) return;
    var lista = List<Notificacion>.from(_todas);

    if (_busqueda.trim().isNotEmpty) {
      final q = _busqueda.toLowerCase().trim();
      lista = lista
          .where((n) =>
              n.titulo.toLowerCase().contains(q) ||
              n.mensaje.toLowerCase().contains(q))
          .toList();
    }

    if (_filtroLeidas != null) {
      lista = lista.where((n) => n.leida == _filtroLeidas).toList();
    }

    if (_filtroFecha != null) {
      final target = DateTime(
        _filtroFecha!.year,
        _filtroFecha!.month,
        _filtroFecha!.day,
      );
      lista = lista.where((n) {
        try {
          final parsed = DateTime.parse(n.fechaCreacion);
          final d = DateTime(parsed.year, parsed.month, parsed.day);
          return d == target;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    _filtradas = lista;
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> marcarComoLeida(
      BuildContext context, Notificacion notificacion) async {
    try {
      final user = await getCurrentUserUseCase();
      if (user == null) return;

      await marcarNotificacionLeidaUseCase(
        idNotificacion: notificacion.idNotificacion,
        idUsuario: user.idUsuario,
        token: user.token,
      );

      // Actualizar en memoria
      _todas = _todas.map((n) {
        if (n.idNotificacion == notificacion.idNotificacion) {
          return Notificacion(
            idNotificacion: n.idNotificacion,
            titulo: n.titulo,
            mensaje: n.mensaje,
            tipoNotificacion: n.tipoNotificacion,
            prioridad: n.prioridad,
            fechaCreacion: n.fechaCreacion,
            fechaEnvio: n.fechaEnvio,
            requiereConfirmacion: n.requiereConfirmacion,
            datosAdicionales: n.datosAdicionales,
            nombreAplicacion: n.nombreAplicacion,
            creadorNombre: n.creadorNombre,
            leida: true,
            fechaLectura: DateTime.now().toIso8601String(),
            confirmada: n.confirmada,
            fechaConfirmacion: n.fechaConfirmacion,
          );
        }
        return n;
      }).toList();

      _aplicarFiltros();
    } catch (_) {
      // Silencioso; la UI recargará en la próxima apertura
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _wsService.desconectar();
    super.dispose();
  }
}


