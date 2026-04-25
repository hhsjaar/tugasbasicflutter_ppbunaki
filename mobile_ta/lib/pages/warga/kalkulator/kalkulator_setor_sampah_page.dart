import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/warga/daftar_sampah_page.dart';
import 'package:mobile_ta/pages/warga/kalkulator/hasil_setor_sampah_page.dart';
import 'package:mobile_ta/services/auth_service.dart';

class KalkulatorSetorSampahPage extends StatefulWidget {
  const KalkulatorSetorSampahPage({super.key});

  @override
  State<KalkulatorSetorSampahPage> createState() =>
      _KalkulatorSetorSampahPageState();
}

class _KalkulatorSetorSampahPageState extends State<KalkulatorSetorSampahPage> {
  List<Map<String, dynamic>> _jenisSampahList = [
    {'jenis_sampah_id': null, 'berat': null},
  ];

  List<Map<String, dynamic>> _jenisSampahOptions = [];

  Future<void> fetchJenisSampah() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
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
        final json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _jenisSampahOptions = List<Map<String, dynamic>>.from(json['data']);
          });
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await fetchJenisSampah(); // Retry after token refresh
        }
      } else {
        debugPrint('Gagal ambil data jenis sampah: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in fetchJenisSampah: $e');
    }
  }

  void _removeJenisSampah(int index) {
    if (_jenisSampahList.length > 1) {
      setState(() {
        _jenisSampahList.removeAt(index);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchJenisSampah();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Kalkulator Setor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(18),

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
                      'Kalkulator Setor Sampah',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kalkulator Setor Sampah adalah untuk menghitung berat dan harga tiap jenis sampah yang diinput.',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF8fd14f).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Jenis Sampah',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Berat (kg)',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._jenisSampahList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<int>(
                                    value: item['jenis_sampah_id'],
                                    hint: Text(
                                      'Pilih jenis',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    items:
                                        _jenisSampahOptions.map((option) {
                                          return DropdownMenuItem<int>(
                                            value: option['id'],
                                            child: Text(
                                              option['nama_sampah'],
                                              style: GoogleFonts.poppins(),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _jenisSampahList[index]['jenis_sampah_id'] =
                                            value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item['berat']?.toString(),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: 'Berat',
                                      hintStyle: GoogleFonts.poppins(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    onChanged: (value) {
                                      final parsed = double.tryParse(value);
                                      String? error;

                                      if (value.isEmpty) {
                                        error = null;
                                      } else if (parsed == null) {
                                        error = 'Harus berupa angka';
                                      } else if (parsed < 0.5) {
                                        error = 'Minimum 0.5 kg';
                                      } else if (parsed > 50) {
                                        error = 'Maksimum 50 kg';
                                      } else if (!RegExp(
                                        r'^\d+(\.\d{1,2})?$',
                                      ).hasMatch(value)) {
                                        error = 'Maksimal 2 angka desimal';
                                      }

                                      setState(() {
                                        if (error != null) {
                                          _jenisSampahList[index]['berat'] =
                                              null;
                                          _jenisSampahList[index]['error'] =
                                              error;
                                        } else {
                                          _jenisSampahList[index]['berat'] =
                                              parsed;
                                          _jenisSampahList[index]['error'] =
                                              null;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeJenisSampah(index),
                                ),
                              ],
                            ),
                            if (item['error'] != null)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['error'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _jenisSampahList.add({
                            'jenis_sampah_id': null,
                            'berat': null,
                            'error': null,
                          });
                        });
                      },
                      icon: Icon(Icons.add, color: Color(0xFF128d54)),
                      label: Text(
                        'Tambah Jenis Sampah',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF128d54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Color(0xFFB2DFDB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(Icons.list_alt, color: Color(0xFF128d54)),
                      label: Text(
                        'Daftar Sampah',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF128d54),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WargaDaftarSampahPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF128d54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final hasError = _jenisSampahList.any(
                          (item) => item['error'] != null,
                        );
                        final isAnyEmpty = _jenisSampahList.any(
                          (item) =>
                              item['jenis_sampah_id'] == null ||
                              item['berat'] == null,
                        );

                        if (hasError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Tolong perbaiki input berat.',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          );
                          return;
                        }

                        if (isAnyEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Harap isi semua jenis sampah dan berat.',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          );
                          return;
                        }

                        final dataSetor =
                            _jenisSampahList.map((item) {
                              return {
                                'jenis_sampah_id': item['jenis_sampah_id'],
                                'berat': item['berat'],
                              };
                            }).toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => HasilSetorSampahPage(
                                  dataSetoran: dataSetor,
                                ),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Hasil',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
