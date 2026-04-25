import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/widget/histori/tarik_saldo_card.dart';
import 'package:google_fonts/google_fonts.dart';

class KumpulanHistoriSaldoPage extends StatefulWidget {
  const KumpulanHistoriSaldoPage({super.key});

  @override
  State<KumpulanHistoriSaldoPage> createState() =>
      _KumpulanHistoriSaldoPageState();
}

class _KumpulanHistoriSaldoPageState extends State<KumpulanHistoriSaldoPage> {
  late Future<List<dynamic>> _historiTarikSaldoList;

  Future<List<dynamic>> fetchHistoriTarikSaldo() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return [];
    }

    try {
    final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/histori-tarik-saldo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'];
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          return await fetchHistoriTarikSaldo();
        }
        return [];
      } else {
        throw Exception('Gagal memuat data histori tarik saldo');
      }
    } catch (e) {
      debugPrint('Error fetch histori tarik saldo: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _historiTarikSaldoList = fetchHistoriTarikSaldo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Histori Tarik Saldo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historiTarikSaldoList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildEmptyState('Terjadi kesalahan saat memuat data.');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState('Belum ada histori penarikan saldo.');
          } else {
            final data = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return TarikSaldoCard(data: item);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox, size: 36, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
