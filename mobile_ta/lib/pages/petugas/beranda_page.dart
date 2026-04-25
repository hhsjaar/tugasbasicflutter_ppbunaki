import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_ta/pages/petugas/artikel/petugas_detail_artikel_page.dart';
import 'package:mobile_ta/pages/petugas/video/petugas_detail_video_page.dart';
import 'package:mobile_ta/widget/petugas_main_widget.dart';
import 'package:mobile_ta/widget/setor_card/setor_card_jemput_baru.dart';
import 'package:mobile_ta/widget/setor_card/setor_card_langsung_baru.dart';
import 'package:mobile_ta/widget/videoCard_widget.dart';
import 'package:mobile_ta/pages/petugas/notifikasi_page.dart';
import '../../widget/eduCard_widget.dart';

class PetugasBerandaPage extends StatelessWidget {
  final Map<String, dynamic>? akunData;
  final Map<String, dynamic>? profilData;
  final List<dynamic> artikelList;
  final List<dynamic> videoList;
  final List<dynamic> setorTerbaruList;

  final String? totalSampah;
  final String? totalSampahBotol;

  const PetugasBerandaPage({
    Key? key,
    required this.artikelList,
    required this.videoList,
    required this.setorTerbaruList,
    this.akunData,
    this.profilData,
    this.totalSampah,
    this.totalSampahBotol,
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
                  style: const TextStyle(
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
                      MaterialPageRoute(
                        builder: (_) => PetugasNotifikasiPage(),
                      ),
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
            // Header Total Sampah Terkumpul
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
                    color: Colors.black.withOpacity(0.25),
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
                    'Total Sampah Terkumpul',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jenis Sampah :',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            totalSampahBotol != null
                                ? '$totalSampahBotol kg'
                                : 'Memuat...',
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Text(
                            "Sampah Botol",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Berat Sampah',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            totalSampah != null
                                ? '$totalSampah kg'
                                : 'Memuat...',
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Text(
                            "Sampah Terkumpul",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Setor Terbaru
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Setor Terbaru",
                        style: GoogleFonts.poppins(
                          color: Color(0xFF128d54),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PetugasMainWrapper(initialMenu: 1),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          "Lainnya",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF128d54),
                          ),
                        ),
                      ),
                    ],
                  ),

                  _buildSetorBaru(),
                ],
              ),
            ),

            // Konten Edukasi (Video)
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
                    color: Colors.black.withOpacity(0.2),
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
                                  (context) =>
                                      PetugasMainWrapper(initialMenu: 2),
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
                                    (_) => PetugasDetailVideoPage(
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

                  // Artikel dibuat grid 2 kolom
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: artikelList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        // crossAxisSpacing: 16,
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
                                    (context) => PetugasDetailArtikelPage(
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
    );
  }

  Widget _buildSetorBaru() {
    if (setorTerbaruList.isEmpty) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.inbox, size: 36, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Belum ada pengajuan setor terbaru.",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          setorTerbaruList.map<Widget>((data) {
            final jenisSetor =
                data['jenis_setor']?.toString().toLowerCase() ?? '';
            if (jenisSetor.contains('langsung')) {
              return SetorCardLangsungBaru(data: data);
            } else if (jenisSetor.contains('jemput')) {
              return SetorCardJemputBaru(data: data);
            } else {
              return SizedBox.shrink();
            }
          }).toList(),
    );
  }
}
