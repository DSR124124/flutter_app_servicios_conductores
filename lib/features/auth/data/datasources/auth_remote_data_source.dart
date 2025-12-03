import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/auth_user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<AuthUserModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              '${AppConfig.backendGestionBaseUrl}${AppConfig.loginEndpoint}',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'usernameOrEmail': usernameOrEmail,
              'password': password,
              'appCode': AppConfig.appCode,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthUserModel.fromJson(data);
      }

      String errorMessage = 'Error desconocido';
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = errorBody['mensaje'] ?? errorBody['message'] ?? errorMessage;
      } catch (_) {}

      if (response.statusCode == 401) {
        throw AppException(errorMessage);
      }

      if (response.statusCode == 403) {
        throw AppException(errorMessage);
      }

      if (response.statusCode >= 500) {
        throw AppException.server();
      }

      throw AppException(errorMessage);
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

