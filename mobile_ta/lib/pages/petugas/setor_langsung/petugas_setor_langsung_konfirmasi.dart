import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/petugas/setor_langsung/petugas_setor_langsung_selesai.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class PetugasSetorLangsungKonfirmasi extends StatefulWidget {
  final List<Map<String, dynamic>> dataSetoran;
  final Map<String, dynamic>? pengajuanSetor;
  final int id;
  final String tanggal;
  final String catatan;

  const PetugasSetorLangsungKonfirmasi({
    required this.pengajuanSetor,
    required this.dataSetoran,
    required this.id,
    required this.tanggal,
    required this.catatan,
    super.key,
  });

  @override
  State<PetugasSetorLangsungKonfirmasi> createState() =>
      _PetugasSetorLangsungKonfirmasiState();
}

class _PetugasSetorLangsungKonfirmasiState
    extends State<PetugasSetorLangsungKonfirmasi> {
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
            item['harga'] = data['harga_per_satuan'];
          } else if (response.statusCode == 401) {
            final refreshed = await authService.refreshToken();
            if (refreshed) {
              return await processSetoran(); // Retry entire process
            }
            break;
          } else {
            debugPrint('Gagal ambil data jenis sampah id: $jenisId');
            continue;
          }
        }

        final int harga = item['harga'] ?? jenisData['harga'];
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

  Future<void> _confirmSetoran() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Token tidak ditemukan")));
      }
      return;
    }

    if (mounted) setState(() => isLoading = true);

    try {
      final resp = await http.post(
        Uri.parse(
          '${dotenv.env['URL']}/setor-langsung/detail-sampah/${widget.id}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'setoran_sampah':
              widget.dataSetoran
                  .map(
                    (item) => {
                      'berat': item['berat'],
                      'jenis_sampah_id': item['jenis_sampah_id'],
                      'harga': item['harga'],
                    },
                  )
                  .toList(),
          'total_berat': totalBerat,
          'total_harga': totalHarga,
        }),
      );

      if (resp.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await _confirmSetoran();
          return;
        }
      }

      final response = jsonDecode(resp.body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Pengajuan berhasil dikonfirmasi.")),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PetugasSetorLangsungSelesai(id: widget.id),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal mengkonfirmasi pengajuan: ${response['message']}",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _confirmSetoran: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil = widget.pengajuanSetor?['user']['profil'];
    final gambarPengguna =
        (profil != null && (profil['gambar_pengguna'] ?? '').isNotEmpty)
            ? profil['gambar_url']
            : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg';

    final namaPengguna = profil?['nama_pengguna'] ?? 'memuat..';

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
          'Setor Langsung',
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
                                    backgroundImage: NetworkImage(
                                      gambarPengguna,
                                    ),
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

                            // Header Layanan
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xff15a864),
                                    Color(0xFF128d54),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Setor Langsung',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Setor Langsung adalah layanan penyetoran sampah langsung ke Bank Sampah oleh pengguna.',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            // const SizedBox(height: 8),
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
                                  Text(
                                    "Detail Penyetoran",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tanggal: ${widget.tanggal}",
                                    style: GoogleFonts.poppins(),
                                  ),
                                  Text(
                                    "Catatan: ${widget.catatan}",
                                    style: GoogleFonts.poppins(),
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
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.white,
                                        ),
                                      ),
                                      Row(
                                        children:
                                            processedSetoran.map((item) {
                                              final double proportion =
                                                  item['berat'] / totalBerat;
                                              return Expanded(
                                                flex:
                                                    (proportion * 1000).round(),
                                                child: Container(
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: Color(
                                                      int.parse(
                                                        item['warna']
                                                            .toString()
                                                            .replaceAll(
                                                              '#',
                                                              '0xff',
                                                            ),
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
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.square,
                                            color: Color(
                                              int.parse(
                                                item['warna']
                                                    .toString()
                                                    .replaceAll('#', '0xff'),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text(item['nama'])),
                                          Text('${item['berat']}kg'),
                                          const SizedBox(width: 16),
                                          Text('Rp ${item['subtotal']}'),
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
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF128d54),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _confirmSetoran,
                        child:
                            isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : Text(
                                  'Konfirmasi Setoran',
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
