import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_ta/pages/warga/artikel/detail_page.dart';
import 'package:mobile_ta/pages/warga/chatbot_page.dart';
import 'package:mobile_ta/pages/warga/daftar_sampah_page.dart';
import 'package:mobile_ta/pages/warga/histori_setor/kumpulan_histori_setor_page.dart';
import 'package:mobile_ta/pages/warga/info_page.dart';
import 'package:mobile_ta/pages/warga/kalkulator/kalkulator_setor_sampah_page.dart';
import 'package:mobile_ta/pages/warga/notifikasi_page.dart';
import 'package:mobile_ta/pages/warga/video/detail_page.dart';
import 'package:mobile_ta/widget/videoCard_widget.dart';
import 'package:mobile_ta/widget/warga_main_widget.dart';
import '../../widget/eduCard_widget.dart';

class WargaBerandaPage extends StatelessWidget {
  final Map<String, dynamic>? akunData;
  final Map<String, dynamic>? profilData;
  final Map<String, dynamic>? saldoData;
  final List<dynamic> artikelList;
  final List<dynamic> videoList;

  final String? totalSampah;

  const WargaBerandaPage({
    Key? key,
    this.akunData,
    this.profilData,
    this.saldoData,
    required this.artikelList,
    required this.videoList,
    this.totalSampah,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    (profilData?['gambar_pengguna'] ?? '').isNotEmpty
                        ? profilData!['gambar_url']
                        : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg',
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  akunData?['username'] ?? 'Memuat...',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WargaNotifikasiPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Total Sampah & Saldo
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6BBE44), Color(0xFF128d54)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.18),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Sampah Terkumpul",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    totalSampah != null ? '$totalSampah kg' : 'Memuat...',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Total Saldo",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    saldoData != null
                        ? 'Rp ${saldoData!['total_saldo']}'
                        : 'Memuat...',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Fitur Lain
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      "Fitur Lain",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF128d54),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _menuItem(
                        Icons.calculate,
                        "Kalkulator",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KalkulatorSetorSampahPage(),
                            ),
                          );
                        },
                      ),
                      _menuItem(
                        Icons.history,
                        "Histori",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KumpulanHistoriSetorPage(),
                            ),
                          );
                        },
                      ),
                      _menuItem(
                        Icons.recycling,
                        "Daftar Sampah",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WargaDaftarSampahPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Konten Edukasi (Video & Artikel)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6BBE44), Color(0xFF128d54)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.12),
                    blurRadius: 12,
                    offset: Offset(0, -8),
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
                        "Edukasi Terbaru",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => WargaMainWrapper(initialMenu: 2),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          "Lainnya",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: videoList.length,
                      itemBuilder: (context, index) {
                        final video = videoList[index];
                        return VideoCard(
                          imageUrl: video['thumbnail_url'] ?? '',
                          title: video['judul_video'] ?? '',
                          date: video['tanggal_format'] ?? '',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => WargaDetailVideoPage(
                                      videoId: video['id'],
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: artikelList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final artikel = artikelList[index];
                        return EduCard(
                          imageUrl: artikel['gambar_url'],
                          title: artikel['judul_artikel'],
                          date: artikel['tanggal_format'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WargaDetailArtikelPage(
                                      id: artikel['id'],
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatbotPage()),
              );
            },
            backgroundColor: Colors.green,
            tooltip: 'Buka Chatbot',
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 30, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
