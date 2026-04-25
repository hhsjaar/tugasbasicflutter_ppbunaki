import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_ta/pages/warga/daftar_sampah_page.dart';
import 'package:mobile_ta/pages/warga/setor_jemput/konfirmasi_page.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/services/auth_service.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class WargaSetorJemput extends StatefulWidget {
  final Map<String, dynamic>? profilData;
  const WargaSetorJemput({this.profilData, super.key});

  @override
  State<WargaSetorJemput> createState() => _WargaSetorJemputState();
}

class _WargaSetorJemputState extends State<WargaSetorJemput> {
  List<Map<String, dynamic>> _jenisSampahList = [
    {'jenis_sampah_id': null, 'berat': null, 'error': null},
  ];
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
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
        backgroundColor: const Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Setor Jemput',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6BBE44), Color(0xFF128d54)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.10),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Setor Jemput',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Setor Jemput adalah layanan penjemputan sampah ke rumah pengguna oleh petugas Bank Sampah, dengan tambahan biaya sebesar Rp1.000 per kilometer.',
                      style: GoogleFonts.poppins(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mohon isi perkiraan berat sampah anda, petugas akan mengukur lagi saat penjemputan",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Tanggal Penyetoran",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // Input tanggal
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF8fd14f).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextFormField(
                  controller: _tanggalController,
                  readOnly: true,
                  style: GoogleFonts.poppins(),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      // Format tanggal: dd/MM/yyyy
                      String formattedDate =
                          "${pickedDate.day.toString().padLeft(2, '0')}/"
                          "${pickedDate.month.toString().padLeft(2, '0')}/"
                          "${pickedDate.year}";
                      _tanggalController.text = formattedDate;
                    }
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Tanggal",
                    hintStyle: GoogleFonts.poppins(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Catatan Petugas (Opsional)",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // Input catatan
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Color(0xFF8fd14f).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextFormField(
                  controller: _catatanController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Masukkan catatan untuk petugas...",
                    hintStyle: GoogleFonts.poppins(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WargaDaftarSampahPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt),
                      label: Text(
                        'Daftar Sampah',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF128d54),
                        side: BorderSide(color: Color(0xFF128d54)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final hasError = _jenisSampahList.any(
                          (item) => item['error'] != null,
                        );
                        final isAnyEmpty = _jenisSampahList.any(
                          (item) =>
                              item['jenis_sampah_id'] == null ||
                              item['berat'] == null,
                        );

                        if (hasError || isAnyEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Harap periksa input Anda')),
                          );
                          return;
                        }

                        final validData =
                            _jenisSampahList
                                .where(
                                  (item) =>
                                      item['jenis_sampah_id'] != null &&
                                      item['berat'] != null,
                                )
                                .toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => WargaKonfirmasiSetorJemputPage(
                                  dataSetoran: validData,
                                  tanggal: _tanggalController.text,
                                  catatan: _catatanController.text,
                                  profilData: widget.profilData,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF128d54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Selanjutnya',
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
