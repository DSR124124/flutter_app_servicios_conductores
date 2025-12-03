import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/perfil_info.dart';
import '../../domain/usecases/get_perfil_info_usecase.dart';

class PerfilProvider extends ChangeNotifier {
  PerfilProvider({required GetPerfilInfoUseCase getPerfilInfoUseCase})
    : _getPerfilInfoUseCase = getPerfilInfoUseCase {
    _loadPerfilSilently();
  }

  final GetPerfilInfoUseCase _getPerfilInfoUseCase;

  PerfilInfo? _perfil;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _error;

  PerfilInfo? get perfil => _perfil;
  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;
  String? get error => _error;

  Future<void> _loadPerfilSilently() async {
    try {
      _perfil = await _getPerfilInfoUseCase();
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = AppException.unknown().message;
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPerfil() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _perfil = await _getPerfilInfoUseCase();
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = AppException.unknown().message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

