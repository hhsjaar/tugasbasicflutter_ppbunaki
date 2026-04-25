import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_ta/models/api_key_model.dart';
import 'package:mobile_ta/services/auth_service.dart';

class ApiService {
  static final String baseUrl = dotenv.env['URL'] ?? '';
  final AuthService _authService = AuthService();

  static Future<ApiKeyResponse> getApiKey() async {
    try {
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api-keys/current'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ApiKeyResponse(
            success: true,
            apiKey: data['data']['key_value'],
            message: 'API key retrieved',
          );
        }
      }
      return ApiKeyResponse(success: false, message: 'No API key found');
    } catch (e) {
      // Fallback to mock
      return ApiKeyResponse(success: true, apiKey: 'mock_openai_api_key');
    }
  }

  static Future<ApiKeyResponse> saveApiKey(String apiKey, {String provider = 'openai'}) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api-keys'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'key_value': apiKey,
          'provider': provider,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return ApiKeyResponse(success: true, message: 'API key saved');
      }
      return ApiKeyResponse(success: false, message: data['message'] ?? 'Failed to save API key');
    } catch (e) {
      return ApiKeyResponse(success: false, message: 'Connection error: $e');
    }
  }
}
