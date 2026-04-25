import 'package:flutter/foundation.dart';
import 'package:mobile_ta/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  // Public getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;

  Future<void> checkAuth() async {
    if (_isLoading) return;

    _isLoading = true;
    // Don't notify listeners here to avoid setState during build

    try {
      _isAuthenticated = await _authService.isLoggedIn();
      if (_isAuthenticated) {
        _userData = await _authService.getUserData();
      }
    } catch (e) {
      debugPrint('Error checking auth: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      // Schedule notification for next frame
      Future.microtask(() => notifyListeners());
    }
  }

  Future<bool> login(String username, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);

      if (result['success'] == true) {
        _isAuthenticated = true;
        _userData = result['data'];
        notifyListeners();

        await Future.microtask(() {});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _isAuthenticated = false;
      _userData = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}
