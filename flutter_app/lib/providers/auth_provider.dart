import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

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

  /// Clears session synchronously (e.g. on auth timeout). Redirect will go to login.
  void clearSessionSafe() {
    _token = null;
    _user = null;
    ApiClient.clearToken();
    _authService.clearToken(); // fire-and-forget
  }

  /// Update in-memory user from a profile API response (e.g. after avatar/cover update).
  /// Use this so the UI updates immediately without waiting for loadUser().
  void updateUserFromMap(Map<String, dynamic>? userMap) {
    if (userMap == null) return;
    try {
      _user = User.fromJson(userMap);
      notifyListeners();
    } catch (_) {}
  }

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
      ApiClient.setToken(savedToken);

      final userJson = await _authService.getCurrentUser();
      final dynamic rawUser = userJson['user'] ?? userJson;

      if (rawUser is Map<String, dynamic>) {
        _user = User.fromJson(rawUser);
      }
    } catch (e) {
      _token = null;
      _user = null;
      await _authService.clearToken();
      ApiClient.clearToken();
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
      ApiClient.setToken(token);

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
      ApiClient.setToken(token);

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
    ApiClient.clearToken();
    _token = null;
    _user = null;

    _isLoading = false;
    notifyListeners();
  }
}
