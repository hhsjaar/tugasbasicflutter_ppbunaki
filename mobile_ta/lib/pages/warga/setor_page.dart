import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_ta/pages/warga/setor_jemput/index_page.dart';
import 'setor_langsung/index_page.dart';

class WargaSetorPage extends StatelessWidget {
  final Map<String, dynamic>? profilData;
  const WargaSetorPage({Key? key, this.profilData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Setor Sampah',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            Text(
              'Pilih Layanan Penyetoran Sampah',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF128d54),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Kartu Setor Langsung
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WargaSetorLangsung()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(18),
                margin: EdgeInsets.only(bottom: 18),
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
                      'Setor Langsung',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Setor Langsung adalah layanan penyetoran dan penukaran sampah menjadi uang yang dilakukan secara langsung di lokasi Bank Sampah.',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Kartu Setor Jemput
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => WargaSetorJemput(profilData: profilData),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
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
                      'Setor Jemput',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Setor Jemput adalah layanan penjemputan sampah ke rumah pengguna oleh petugas Bank Sampah, dengan tambahan biaya sebesar Rp1.000 per kilometer.',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF128d54)),
              ),
              child: Text(
                'Pelayanan Setor Langsung dan Setor Jemput akan dilayani pada jam kerja Senin sampai Jumat, yaitu pukul 09.00 – 17.00.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
