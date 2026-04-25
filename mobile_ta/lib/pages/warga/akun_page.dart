import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/warga/histori_saldo/kumpulan_histori_saldo_page.dart';
import 'package:mobile_ta/pages/warga/info_page.dart';
import 'package:mobile_ta/pages/warga/notifikasi_page.dart';
import 'package:mobile_ta/pages/warga/tarik_saldo_page.dart';
import 'package:mobile_ta/providers/auth_provider.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'edit_profil_page.dart';
import '../auth/login_page.dart';
import 'package:google_fonts/google_fonts.dart';

class WargaAkunPage extends StatefulWidget {
  final Map<String, dynamic>? akunData;
  final Map<String, dynamic>? profilData;
  final Map<String, dynamic>? saldoData;

  const WargaAkunPage({
    Key? key,
    this.akunData,
    this.profilData,
    this.saldoData,
  }) : super(key: key);

  @override
  State<WargaAkunPage> createState() => _WargaAkunPageState();
}

class _WargaAkunPageState extends State<WargaAkunPage> {
  int jumlahPermintaanTarikSaldo = 0;

  Future<void> logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<int> fetchPermintaanTarikSaldo() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return 0;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/permintaan-tarik-saldo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['data'] is int ? jsonData['data'] : 0;
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          return await fetchPermintaanTarikSaldo();
        }
        return 0;
      } else {
        throw Exception('Gagal memuat data permintaan tarik saldo');
      }
    } catch (e) {
      debugPrint('Error fetch permintaan tarik saldo: $e');
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPermintaanTarikSaldo().then((value) {
      setState(() {
        jumlahPermintaanTarikSaldo = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final akunData = widget.akunData;
    final profilData = widget.profilData;
    final saldoData = widget.saldoData;
    final bool isTarikSaldoAktif =
        saldoData != null &&
        jumlahPermintaanTarikSaldo < saldoData['total_saldo'];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Akun Saya",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(16)),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      (profilData?['gambar_pengguna'] ?? '').isNotEmpty
                          ? profilData!['gambar_url']
                          : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    akunData?['username'] ?? 'Memuat...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  Text(
                    akunData?['email'] ?? 'Memuat...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: 160,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    WargaEditProfilPage(profilData: profilData),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF128d54),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        shadowColor: Colors.green.withOpacity(0.15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Edit Akun",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Saldo Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff15a864), Color(0xFF128d54)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.20),
                    blurRadius: 10,
                    offset: Offset(0, 2),
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
                        "Saldo Saya",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Permintaan Saldo",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        saldoData != null
                            ? 'Rp ${saldoData['total_saldo']}'
                            : 'Memuat...',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Rp $jumlahPermintaanTarikSaldo',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KumpulanHistoriSaldoPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF128d54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(Icons.history, size: 18),
                        label: Text(
                          "Histori Saldo",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            isTarikSaldoAktif
                                ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => WargaTarikSaldoPage(
                                            no_hp:
                                                profilData?['no_hp_pengguna'],
                                            saldo: saldoData,
                                            permintaanSaldo:
                                                jumlahPermintaanTarikSaldo,
                                          ),
                                    ),
                                  );
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isTarikSaldoAktif
                                  ? Colors.white
                                  : Colors.grey.shade400,
                          foregroundColor:
                              isTarikSaldoAktif
                                  ? Color(0xFF128d54)
                                  : Colors.grey.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: isTarikSaldoAktif ? 2 : 0,
                        ),
                        icon: Icon(Icons.money, size: 18),
                        label: Text(
                          "Tarik Saldo",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // SizedBox(height: 16),

            // Menu lainnya
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                children: [
                  _buildMenuItem(
                    Icons.info,
                    "Info",
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WargaInfoPage()),
                      );
                    },
                  ),
                  // SizedBox(height: 4),
                  _buildMenuItem(
                    Icons.mail_outline,
                    "Notifikasi",
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WargaNotifikasiPage(),
                        ),
                      );
                    },
                  ),
                  // SizedBox(height: 4),
                  _buildMenuItem(
                    Icons.logout,
                    "Logout",
                    iconColor: Colors.white,
                    onTap: () => logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff15a864), Color(0xFF128d54)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? Colors.white),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.white,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
