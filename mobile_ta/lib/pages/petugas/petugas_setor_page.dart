import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/widget/setor_card/setor_card_jemput_baru.dart';
import 'package:mobile_ta/widget/setor_card/setor_card_jemput_proses.dart';
import 'package:mobile_ta/widget/setor_card/setor_card_jemput_selesai.dart';
import 'package:mobile_ta/widget/setor_card/setor_card_langsung_selesai.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widget/setor_card/setor_card_langsung_baru.dart';

class PetugasSetorPage extends StatefulWidget {
  @override
  _PetugasSetorPageState createState() => _PetugasSetorPageState();
}

class _PetugasSetorPageState extends State<PetugasSetorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data
  late Future<List<dynamic>> _setorBaruList;
  late Future<List<dynamic>> _setorProsesList;
  late Future<List<dynamic>> _setorSelesaiList;

  Future<List<dynamic>> fetchSetorBaru() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/setor-baru'),
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
          return await fetchSetorBaru(); // Retry after token refresh
        }
        return [];
      } else {
        throw Exception(
          'Gagal memuat data setor baru. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in fetchSetorBaru: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchSetorProses() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/setor-proses'),
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
          return await fetchSetorProses(); // Retry after token refresh
        }
        return [];
      } else {
        throw Exception(
          'Gagal memuat data setor proses. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in fetchSetorProses: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchSetorSelesai() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/setor-selesai'),
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
          return await fetchSetorSelesai(); // Retry after token refresh
        }
        return [];
      } else {
        throw Exception(
          'Gagal memuat data setor selesai. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in fetchSetorSelesai: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setorBaruList = fetchSetorBaru();
    _setorProsesList = fetchSetorProses();
    _setorSelesaiList = fetchSetorSelesai();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Daftar Setor Sampah",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Color(0xFF128d54),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Color(0xFF128d54),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Text("Baru", textAlign: TextAlign.center),
                    ),
                  ),
                  Tab(
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Text("Proses", textAlign: TextAlign.center),
                    ),
                  ),
                  Tab(
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      child: Text("Selesai", textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSetorBaru(),
                _buildSetorProses(),
                _buildSetorSelesai(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetorBaru() {
    return FutureBuilder<List<List<dynamic>>>(
      future: Future.wait([_setorBaruList]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Terjadi kesalahan saat memuat data"));
        }

        final baruData = snapshot.data?[0] ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection(
                "Setor Terbaru",
                baruData.isNotEmpty
                    ? baruData.map<Widget>((data) {
                      final jenisSetor =
                          data['jenis_setor']?.toString().toLowerCase();
                      if (jenisSetor == 'setor langsung') {
                        return SetorCardLangsungBaru(data: data);
                      } else if (jenisSetor == 'setor jemput') {
                        return SetorCardJemputBaru(data: data);
                      } else {
                        return SizedBox.shrink(); // fallback jika jenis_setor tidak dikenali
                      }
                    }).toList()
                    : [
                      _buildEmptyState(
                        "Belum ada setoran langsung/jemput baru",
                      ),
                    ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetorProses() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_setorProsesList]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Gagal memuat data"));
        }

        final baruList = snapshot.data?[0] ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection(
                "Setor Proses",
                baruList.isNotEmpty
                    ? List<Widget>.from(
                      baruList.map((data) => SetorCardJemputProses(data: data)),
                    )
                    : [_buildEmptyState("Tidak ada data setor proses")],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetorSelesai() {
    return FutureBuilder<List<List<dynamic>>>(
      future: Future.wait([_setorSelesaiList]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Terjadi kesalahan saat memuat data"));
        }

        final baruData = snapshot.data?[0] ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection(
                "Setor Selesai",
                baruData.isNotEmpty
                    ? baruData.map<Widget>((data) {
                      final jenisSetor =
                          data['jenis_setor']?.toString().toLowerCase();
                      if (jenisSetor == 'setor langsung') {
                        return SetorCardLangsungSelesai(data: data);
                      } else if (jenisSetor == 'setor jemput') {
                        return SetorCardJemputSelesai(data: data);
                      } else {
                        return SizedBox.shrink(); // fallback jika jenis_setor tidak dikenali
                      }
                    }).toList()
                    : [
                      _buildEmptyState(
                        "Belum ada setoran langsung/jemput baru",
                      ),
                    ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> cards) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF128d54),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Column(children: cards),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFB2DFDB)),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox, size: 36, color: Color(0xFF8fd14f)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
