import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class WargaDaftarSampahPage extends StatefulWidget {
  const WargaDaftarSampahPage({super.key});

  @override
  State<WargaDaftarSampahPage> createState() => _WargaDaftarSampahPageState();
}

class _WargaDaftarSampahPageState extends State<WargaDaftarSampahPage> {
  List<dynamic> sampahList = [];
  bool isLoading = true; // Tambahkan ini

  Future<void> loadSampah() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/jenis-sampah'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (mounted) {
          setState(() {
            sampahList = jsonData['data'];
          });
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await loadSampah();
        }
      } else {
        debugPrint('Gagal fetch: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal load data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadSampah();
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
          'Daftar Sampah',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF128d54)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Berikut adalah daftar jenis sampah yang diterima oleh sistem, beserta harga jual per kilogramnya:",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (sampahList.isEmpty)
                      Center(
                        child: Text(
                          "Tidak ada data tersedia.",
                          style: GoogleFonts.poppins(fontSize: 15),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: sampahList.length,
                        itemBuilder: (context, idx) {
                          final sampah = sampahList[idx];
                          final nama =
                              sampah['nama_sampah'] ?? 'Tidak diketahui';
                          final harga =
                              sampah['harga_per_satuan']?.toString() ?? '-';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.10),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(
                                  Icons.recycling,
                                  color: Color(0xFF128d54),
                                ),
                              ),
                              title: Text(
                                nama,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF128d54),
                                ),
                              ),
                              subtitle: Text(
                                "Harga: Rp$harga /kg",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
    );
  }
}
