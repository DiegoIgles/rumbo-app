import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

enum AuthStatus { loading, signedOut, signedIn }

/// Estado de sesión de la app, persistido en SharedPreferences.
/// Equivalente a src/context/AuthContext.tsx del panel web.
class AuthController extends ChangeNotifier {
  static const _tokenKey = 'rumbo_token';
  static const _roleKey = 'rumbo_role';

  late final ApiClient api = ApiClient(tokenProvider: () => _token);

  String? _token;
  String? _role;
  AppUser? _user;
  AuthStatus _status = AuthStatus.loading;

  String? get token => _token;
  String? get role => _role;
  AppUser? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.signedIn;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _role = prefs.getString(_roleKey);

    if (_token == null) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    try {
      _user = await api.me();
      _status = AuthStatus.signedIn;
    } catch (_) {
      await _clear();
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email, password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.accessToken);
    await prefs.setString(_roleKey, result.role);
    _token = result.accessToken;
    _role = result.role;
    _user = await api.me();
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String role = 'joven',
  }) async {
    await api.register(nombre: nombre, email: email, password: password, role: role);
    await login(email, password);
  }

  Future<void> logout() async {
    await _clear();
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    _token = null;
    _role = null;
    _user = null;
  }
}
