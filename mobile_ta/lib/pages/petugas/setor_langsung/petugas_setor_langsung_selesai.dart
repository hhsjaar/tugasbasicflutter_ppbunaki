import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/widget/petugas_main_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class PetugasSetorLangsungSelesai extends StatefulWidget {
  final int id;
  const PetugasSetorLangsungSelesai({required this.id, super.key});

  @override
  State<PetugasSetorLangsungSelesai> createState() =>
      _PetugasSetorLangsungSelesaiState();
}

class _PetugasSetorLangsungSelesaiState
    extends State<PetugasSetorLangsungSelesai> {
  Map<String, dynamic>? pengajuanDetailSetor;
  Map<int, Map<String, dynamic>> jenisSampahCache = {};
  List<Map<String, dynamic>> processedSetoran = [];
  double totalBerat = 0.0;
  int totalHarga = 0;
  int biayaLayanan = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchPengajuanDetailSetor();
    await processSetoranData();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchPengajuanDetailSetor() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      throw Exception('Authentication required');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/setor-langsung/selesai/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (mounted) {
          setState(() {
            pengajuanDetailSetor = data;
          });
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await fetchPengajuanDetailSetor(); // Retry after refresh
        } else {
          throw Exception('Session expired');
        }
      } else {
        throw Exception(
          'fetchPengajuanSetor failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in fetchPengajuanDetailSetor: $e');
      rethrow;
    }
  }

  Future<void> processSetoranData() async {
    if (pengajuanDetailSetor == null) return;

    try {
      final detailSetoran = pengajuanDetailSetor!['input_detail'];
      final setoranSampah = detailSetoran['setoran_sampah'] as List;

      // Reset processed data
      processedSetoran.clear();
      totalBerat = (detailSetoran['total_berat'] as num).toDouble();
      totalHarga = detailSetoran['total_harga'] as int;

      for (var item in setoranSampah) {
        final int jenisId = item['jenis_sampah_id'];
        final double berat = (item['berat'] as num).toDouble();
        final int harga =
            item['harga']
                as int;

        final int subtotal = (berat * harga).round();

        // Tetap ambil nama dan warna dari cache/API untuk tampilan
        if (!jenisSampahCache.containsKey(jenisId)) {
          final authService = AuthService();
          final token = await authService.getToken();
          if (token == null) return;

          final response = await http.get(
            Uri.parse('${dotenv.env['URL']}/jenis-sampah/$jenisId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body)['data'];
            jenisSampahCache[jenisId] = {
              'nama': data['nama_sampah'],
              'warna': data['warna_indikasi'], // Harga tidak disimpan di cache
            };
          }else if (response.statusCode == 401) {
            final refreshed = await authService.refreshToken();
            if (refreshed) {
              return await processSetoranData(); // Retry entire process
            }
            return; // Skip if refresh fails
          }
        }

        processedSetoran.add({
          'nama': jenisSampahCache[jenisId]?['nama'] ?? 'Unknown',
          'berat': berat,
          'harga': harga, // Gunakan harga dari data setoran
          'subtotal': subtotal,
          'warna': jenisSampahCache[jenisId]?['warna'] ?? '#999999',
        });
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error in processSetoranData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || pengajuanDetailSetor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Setor Sampah Langsung")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profil = pengajuanDetailSetor!['user']?['profil'];
    final gambarPengguna =
        (profil != null && (profil['gambar_pengguna'] ?? '').isNotEmpty)
            ? profil['gambar_url']
            : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg';

    final namaPengguna = profil?['nama_pengguna'] ?? 'memuat..';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color((0xFF128d54)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => PetugasMainWrapper(initialMenu: 1),
                ),
                (Route<dynamic> route) => false,
              ),
        ),
        title: Text(
          "Setor Langsung",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informasi Pengguna
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.20),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(gambarPengguna),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              namaPengguna,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Jenis dan Berat Sampah',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Grafik Sampah
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.20),
                            blurRadius: 16,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
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
                                    '${totalBerat.toStringAsFixed(1)}kg',
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
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
                                    '${item['berat']}kg',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Rp ${item['subtotal']}',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Estimasi Insentif',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Estimasi Insentif
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.20),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total harga sampah',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF128d54),
                                ),
                              ),
                              Text(
                                'Rp $totalHarga',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF128d54),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF128d54),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed:
                    () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PetugasMainWrapper(initialMenu: 1),
                      ),
                      (Route<dynamic> route) => false,
                    ),
                child: Text(
                  'Kembali Ke Beranda',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
