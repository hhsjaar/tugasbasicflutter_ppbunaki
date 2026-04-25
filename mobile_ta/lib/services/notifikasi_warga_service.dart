import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/models/notification_model.dart';
import 'package:mobile_ta/services/auth_service.dart';

class NotifikasiWargaService {
  final AuthService _authService = AuthService();
  static final _baseUrl = dotenv.env['URL'] ?? '';

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
      }
      return _mockNotifications();
    } catch (e) {
      return _mockNotifications();
    }
  }

  Future<List<NotificationModel>> _mockNotifications() async {
    return [
      NotificationModel(
        id: 1,
        title: 'Notifikasi Mock untuk Warga 1',
        body: 'Ini adalah notifikasi mock untuk warga.',
        createdAt: DateTime.now(),
        isRead: false,
      ),
      NotificationModel(
        id: 2,
        title: 'Notifikasi Mock untuk Warga 2',
        body: 'Notifikasi kedua yang dihasilkan secara lokal.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
    ];
  }

  Future<void> markAsRead(int id) async {
    try {
      final token = await _authService.getToken();
      await http.put(
        Uri.parse('$_baseUrl/notifications/$id/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await _authService.getToken();
      await http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }
}
