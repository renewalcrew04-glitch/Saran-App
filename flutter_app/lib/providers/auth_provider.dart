import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _isAuthenticated = true;
      // Set token in AuthService
      await _authService.setToken(_token!);
      // Load user data
      await getCurrentUser();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        _isAuthenticated = true;

        // Save token in both SharedPreferences and AuthService
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await _authService.setToken(_token!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.register(username, email, password, name);
      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        _isAuthenticated = true;

        // Save token in both SharedPreferences and AuthService
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await _authService.setToken(_token!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> getCurrentUser() async {
    try {
      final response = await _authService.getCurrentUser();
      if (response['success'] == true) {
        _user = User.fromJson(response['user']);
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await _authService.clearToken();
    _token = null;
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
