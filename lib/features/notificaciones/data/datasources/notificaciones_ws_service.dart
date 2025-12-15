import 'dart:convert';

import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../../../../core/constants/app_config.dart';
import '../models/notificacion_model.dart';
import '../../domain/entities/notificacion.dart';

typedef OnNuevaNotificacion = void Function(Notificacion notificacion);

class NotificacionesWsService {
  StompClient? _client;

  bool get isConnected => _client?.connected ?? false;

  void conectar({
    required String token,
    required OnNuevaNotificacion onNueva,
  }) {
    if (_client != null && _client!.connected) return;

    final baseUrl = AppConfig.backendGestionBaseUrl; // ej: https://dominio.com/gestion
    // Endpoint SockJS (NO agregar sufijo /websocket, la librería lo maneja internamente)
    final url = '$baseUrl/ws-notificaciones';

    _client = StompClient(
      config: StompConfig.SockJS(
        url: url,
        onConnect: (StompFrame frame) {
          // print('WS conectado: ${frame.headers}');
          _client!.subscribe(
            destination: '/topic/notificaciones-nuevas',
            callback: (StompFrame msg) {
              if (msg.body == null) return;
              try {
                final data = jsonDecode(msg.body!) as Map<String, dynamic>;
                final notif = NotificacionModel.fromJson(data);
                onNueva(notif);
              } catch (_) {
                // ignorar mensajes inválidos
              }
            },
          );
        },
        onWebSocketError: (dynamic _) {},
        reconnectDelay: const Duration(milliseconds: 5000),
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    _client!.activate();
  }

  void desconectar() {
    _client?.deactivate();
    _client = null;
  }
}


