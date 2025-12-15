import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/usecases/get_mis_notificaciones_usecase.dart';
import '../../domain/usecases/marcar_notificacion_leida_usecase.dart';
import '../../data/datasources/notificaciones_ws_service.dart';

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
  bool _disposed = false;

  Future<void> cargarNotificaciones(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await getCurrentUserUseCase();
      if (user == null) {
        AppToast.show(
          context,
          message: 'No se pudo obtener el usuario actual',
          type: ToastType.error,
        );
        return;
      }

      _todas = await getMisNotificacionesUseCase(
        idUsuario: user.idUsuario,
        token: user.token,
      );
      _aplicarFiltros();

      // Conectar WebSocket (solo si no estaba conectado)
      if (!_wsService.isConnected) {
        _wsService.conectar(
          token: user.token,
          onNueva: (Notificacion n) async {
            // Añadir a la lista en memoria
            _todas.insert(0, n);
            _aplicarFiltros();
          },
        );
      }
    } catch (e) {
      AppToast.show(
        context,
        message: 'Error al cargar notificaciones',
        type: ToastType.error,
      );
    } finally {
      _isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
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


