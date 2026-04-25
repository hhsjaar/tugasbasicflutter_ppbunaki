import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailHistoriSaldoPage extends StatefulWidget {
  final int id;
  const DetailHistoriSaldoPage({required this.id, super.key});

  @override
  State<DetailHistoriSaldoPage> createState() => _DetailHistoriSaldoPageState();
}

class _DetailHistoriSaldoPageState extends State<DetailHistoriSaldoPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDetailHistoriTarikSaldo();
  }

  Future<void> fetchDetailHistoriTarikSaldo() async {
    final authService = AuthService();
    final token = await authService.getToken();

    try {
      if (token == null) {
        if (mounted) {
          setState(() {
            errorMessage = 'Token tidak ditemukan';
            isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/histori-tarik-saldo/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (mounted) {
          setState(() {
            data = jsonData['data'];
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await fetchDetailHistoriTarikSaldo();
        } else if (mounted) {
          setState(() {
            errorMessage = 'Session expired. Please login again';
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Gagal memuat data histori tarik saldo';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Terjadi kesalahan: $e';
          isLoading = false;
        });
      }
    }
  }

  String formatCurrency(int amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return Colors.orange;
      case 'terima':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  String formatMetode(String metode) {
    final lower = metode.toLowerCase();
    if (lower == 'dana' || lower == 'shopeepay') {
      return 'E-Wallet (${_capitalize(metode)})';
    } else if (lower == 'bni' || lower == 'bca') {
      return 'Transfer Bank (${metode.toUpperCase()})';
    }
    return _capitalize(metode);
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Histori Tarik Saldo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                child: Text(
                  errorMessage!,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                ),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.10),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF128d54),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            formatCurrency(data!['jumlah_saldo']),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF128d54),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Divider(),
                        _buildRow(
                          'Status',
                          data!['status'] ?? 'Tidak diketahui',
                          valueColor: getStatusColor(data!['status'] ?? ''),
                        ),
                        Divider(),
                        _buildRow(
                          'Tanggal Penarikan',
                          data!['tanggal_format'] ?? 'Tidak diketahui',
                        ),
                        Divider(),
                        _buildRow(
                          'Metode',
                          formatMetode(data!['metode'] ?? ''),
                        ),
                        Divider(),
                        _buildRow(
                          'Nomor Tarik Saldo',
                          data!['nomor_tarik_saldo'] ?? '-',
                        ),
                        Divider(),
                        _buildRow(
                          'Pesan',
                          data!['pesan'] ?? 'Tidak ada pesan!',
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Color(0xFFB2DFDB)),
                            ),
                            child: Text(
                              "Jika ada kendala, silakan hubungi admin bank sampah.",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
