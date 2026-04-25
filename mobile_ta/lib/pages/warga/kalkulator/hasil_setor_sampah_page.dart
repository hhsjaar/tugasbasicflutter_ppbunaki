import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HasilSetorSampahPage extends StatefulWidget {
  final List<Map<String, dynamic>> dataSetoran;
  const HasilSetorSampahPage({required this.dataSetoran, super.key});

  @override
  State<HasilSetorSampahPage> createState() => _HasilSetorSampahPageState();
}

class _HasilSetorSampahPageState extends State<HasilSetorSampahPage> {
  final Map<int, Map<String, dynamic>> jenisSampahCache = {};
  List<Map<String, dynamic>> processedSetoran = [];
  double totalBerat = 0.0;
  int totalHarga = 0;
  int biayaLayanan = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    processSetoran();
  }

  Future<void> processSetoran() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      if (mounted) setState(() => isLoading = false);
      return;
    }

    // Reset values
    processedSetoran.clear();
    totalBerat = 0;
    totalHarga = 0;

    try {
      for (var item in widget.dataSetoran) {
        final int jenisId = item['jenis_sampah_id'];
        final double berat = item['berat'] * 1.0;

        Map<String, dynamic> jenisData;
        if (jenisSampahCache.containsKey(jenisId)) {
          jenisData = jenisSampahCache[jenisId]!;
        } else {
          final response = await http.get(
            Uri.parse('${dotenv.env['URL']}/jenis-sampah/$jenisId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body)['data'];
            jenisData = {
              'nama': data['nama_sampah'],
              'harga': data['harga_per_satuan'],
              'warna': data['warna_indikasi'],
            };
            jenisSampahCache[jenisId] = jenisData;
          } else if (response.statusCode == 401) {
            final refreshed = await authService.refreshToken();
            if (refreshed) {
              return await processSetoran(); // Retry entire process
            }
            break; // Skip if refresh fails
          } else {
            debugPrint('Gagal ambil data jenis sampah id: $jenisId');
            continue;
          }
        }

        final int harga = jenisData['harga'];
        final int subtotal = (berat * harga).round();

        processedSetoran.add({
          'nama': jenisData['nama'],
          'berat': berat,
          'harga': harga,
          'subtotal': subtotal,
          'warna': jenisData['warna'],
        });

        totalBerat += berat;
        totalHarga += subtotal;
      }
    } catch (e) {
      debugPrint('Error in processSetoran: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF128d54)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kalkulator Setor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6BBE44), Color(0xFF128d54)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.12),
                              offset: Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Hasil Kalkulator Setor Sampah',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Berikut adalah hasil perhitungan berat dan insentif dari sampah yang Anda input.',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 18),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jenis dan Berat Sampah',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF128d54),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Stack(
                              children: [
                                Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[300],
                                  ),
                                ),
                                Row(
                                  children:
                                      processedSetoran.map((item) {
                                        final double proportion =
                                            item['berat'] / totalBerat;
                                        return Expanded(
                                          flex: (proportion * 1000).round(),
                                          child: Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Color(
                                                int.parse(
                                                  item['warna']
                                                      .toString()
                                                      .replaceAll('#', '0xff'),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '${totalBerat.toStringAsFixed(1)} kg',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...processedSetoran.map((item) {
                              return Row(
                                children: [
                                  Icon(
                                    Icons.square,
                                    color: Color(
                                      int.parse(
                                        item['warna'].toString().replaceAll(
                                          '#',
                                          '0xff',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item['nama'],
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  Text(
                                    '${item['berat']} kg',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 18),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimasi Insentif',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF128d54),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Perkiraan Insentif',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rp ${totalHarga - biayaLayanan}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
