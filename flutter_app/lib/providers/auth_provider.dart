import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get loading => _isLoading;

  User? _user;
  User? get user => _user;

  String? _token;
  String? get token => _token;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // =========================
  // LOAD USER (MANUAL)
  // =========================
  Future<void> loadUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userJson = await _authService.getCurrentUser();
      final dynamic rawUser = userJson['user'] ?? userJson;

      if (rawUser is Map<String, dynamic>) {
        _user = User.fromJson(rawUser);
      }
    } catch (e) {
      // keep old user
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOAD USER FROM TOKEN
  // =========================
  Future<void> loadUserFromToken() async {
    try {
      _isLoading = true;
      notifyListeners();

      final savedToken = await _authService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        _token = null;
        _user = null;
        return;
      }

      _token = savedToken;

      final userJson = await _authService.getCurrentUser();
      final dynamic rawUser = userJson['user'] ?? userJson;

      if (rawUser is Map<String, dynamic>) {
        _user = User.fromJson(rawUser);
      }
    } catch (e) {
      _token = null;
      _user = null;
      await _authService.clearToken();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOGIN (FIXED)
  // =========================
  Future<bool> login(
    String email,
    String password,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _authService.login(email, password);

      final token = data['token']?.toString();
      final dynamic rawUser = data['user'];

      if (token == null || token.isEmpty) {
        throw Exception("Token not received from backend");
      }

      await _authService.setToken(token);
      _token = token;

      if (rawUser is Map<String, dynamic>) {
        _user = User.fromJson(rawUser);
      } else {
        // fallback to /me
        final meData = await _authService.getCurrentUser();
        final dynamic meUser = meData['user'] ?? meData;
        if (meUser is Map<String, dynamic>) {
          _user = User.fromJson(meUser);
        }
      }

      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // REGISTER (UNCHANGED)
  // =========================
  Future<bool> register(
    String username,
    String email,
    String password,
    String name,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data =
          await _authService.register(username, email, password, name);

      final token = data['token']?.toString();
      final dynamic rawUser = data['user'];

      if (token == null || token.isEmpty) {
        throw Exception("Token not received from backend");
      }

      await _authService.setToken(token);
      _token = token;

      if (rawUser is Map<String, dynamic>) {
        _user = User.fromJson(rawUser);
      } else {
        final meData = await _authService.getCurrentUser();
        final dynamic meUser = meData['user'] ?? meData;
        if (meUser is Map<String, dynamic>) {
          _user = User.fromJson(meUser);
        }
      }

      return true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.clearToken();
    _token = null;
    _user = null;

    _isLoading = false;
    notifyListeners();
  }
}
