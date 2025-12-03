import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exception.dart';

class PerfilRemoteDataSource {
  PerfilRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> fetchPerfil({required String token}) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '${AppConfig.backendServiciosBaseUrl}/api/clientes/mi-perfil',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        throw AppException.sessionExpired();
      }
      if (response.statusCode == 403) {
        throw AppException.forbidden();
      }
      if (response.statusCode >= 500) {
        throw AppException.server();
      }

      throw AppException.unknown();
    } on SocketException catch (_, stackTrace) {
      throw AppException.network(stackTrace);
    } on TimeoutException catch (_, stackTrace) {
      throw AppException.timeout(stackTrace);
    } on AppException {
      rethrow;
    } catch (_, stackTrace) {
      throw AppException.unknown(stackTrace);
    }
  }
}

