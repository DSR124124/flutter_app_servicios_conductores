import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    if (_client != null && _client!.connected) {
      debugPrint('WebSocket ya está conectado');
      return;
    }

    final baseUrl = AppConfig.backendGestionBaseUrl; // ej: https://dominio.com/gestion
    // Endpoint SockJS (NO agregar sufijo /websocket, la librería lo maneja internamente)
    final url = '$baseUrl/ws-notificaciones';
    
    debugPrint('Intentando conectar WebSocket a: $url');

    _client = StompClient(
      config: StompConfig.SockJS(
        url: url,
        onConnect: (StompFrame frame) {
          debugPrint('WebSocket conectado exitosamente');
          _client!.subscribe(
            destination: '/topic/notificaciones-nuevas',
            callback: (StompFrame msg) {
              if (msg.body == null) {
                debugPrint('Mensaje WebSocket recibido sin body');
                return;
              }
              try {
                debugPrint('Mensaje WebSocket recibido: ${msg.body}');
                final data = jsonDecode(msg.body!) as Map<String, dynamic>;
                final notif = NotificacionModel.fromJson(data);
                debugPrint('Notificación parseada: ${notif.titulo}');
                onNueva(notif);
              } catch (e) {
                debugPrint('Error al parsear mensaje WebSocket: $e');
                debugPrint('Body del mensaje: ${msg.body}');
              }
            },
          );
          debugPrint('Suscrito a /topic/notificaciones-nuevas');
        },
        onWebSocketError: (dynamic error) {
          debugPrint('Error en WebSocket: $error');
        },
        onStompError: (StompFrame frame) {
          debugPrint('Error STOMP: ${frame.body}');
        },
        onDisconnect: (StompFrame frame) {
          debugPrint('WebSocket desconectado');
        },
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
    debugPrint('WebSocket activado');
  }

  void desconectar() {
    _client?.deactivate();
    _client = null;
  }
}


