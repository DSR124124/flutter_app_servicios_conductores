import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user_model.dart';

class AuthLocalDataSource {
  static const _userKey = 'auth_user';

  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> cacheUser(AuthUserModel user) async {
    await _ensurePrefs();
    await _prefs!.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<AuthUserModel?> getCachedUser() async {
    await _ensurePrefs();
    final jsonString = _prefs!.getString(_userKey);
    if (jsonString == null) return null;
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return AuthUserModel.fromJson(data);
    } catch (_) {
      await _prefs!.remove(_userKey);
      return null;
    }
  }

  Future<void> clear() async {
    await _ensurePrefs();
    await _prefs!.remove(_userKey);
  }
}

