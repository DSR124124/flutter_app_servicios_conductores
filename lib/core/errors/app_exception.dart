import '../constants/app_strings.dart';

class AppException implements Exception {
  const AppException(this.message, {this.stackTrace});

  final String message;
  final StackTrace? stackTrace;

  factory AppException.network([StackTrace? stackTrace]) =>
      AppException(AppStrings.networkError, stackTrace: stackTrace);

  factory AppException.server([StackTrace? stackTrace]) =>
      AppException(AppStrings.serverError, stackTrace: stackTrace);

  factory AppException.invalidCredentials([StackTrace? stackTrace]) =>
      AppException(AppStrings.invalidCredentials, stackTrace: stackTrace);

  factory AppException.unauthorized([StackTrace? stackTrace]) =>
      AppException(AppStrings.unauthorizedError, stackTrace: stackTrace);

  factory AppException.forbidden([StackTrace? stackTrace]) =>
      AppException(AppStrings.forbiddenError, stackTrace: stackTrace);

  factory AppException.timeout([StackTrace? stackTrace]) =>
      AppException(AppStrings.timeoutError, stackTrace: stackTrace);

  factory AppException.sessionExpired([StackTrace? stackTrace]) =>
      AppException(AppStrings.sessionExpired, stackTrace: stackTrace);

  factory AppException.unknown([StackTrace? stackTrace]) =>
      AppException(AppStrings.unknownError, stackTrace: stackTrace);

  @override
  String toString() => message;
}

