import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static final _baseUrl = dotenv.env['URL'] ?? '';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _tokenRefreshTimer;

  Future<Map<String, dynamic>> login(String username, String password) async {
    // Mock login - always succeed
    final data = {
      'access_token': 'mock_access_token',
      'refresh_token': 'mock_refresh_token',
      'data': {
        'id': 1,
        'username': username,
        'role': username == 'petugas' ? 'petugas' : 'warga',
        'name': 'Mock User',
      }
    };
    await _saveAuthData(data);
    _startTokenRefreshTimer();
    return {'success': true, 'data': data['data']};
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['access_token']);
    await _storage.write(key: 'refresh_token', value: data['refresh_token']);
    await _storage.write(key: 'user_data', value: jsonEncode(data['data']));
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<bool> refreshToken() async {
    // Mock refresh - always succeed
    await _storage.write(key: 'access_token', value: 'mock_access_token_refreshed');
    return true;
  }

  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 15), (
      timer,
    ) async {
      await refreshToken();
    });
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _tokenRefreshTimer?.cancel();
  }
}
