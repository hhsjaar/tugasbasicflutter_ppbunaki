import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_ta/pages/petugas/video/petugas_detail_video_page.dart';
import 'package:mobile_ta/widget/videoCard_widget.dart';

class PetugasKumpulanVideoPage extends StatefulWidget {
  const PetugasKumpulanVideoPage({super.key});

  @override
  State<PetugasKumpulanVideoPage> createState() =>
      _PetugasKumpulanVideoPageState();
}

class _PetugasKumpulanVideoPageState extends State<PetugasKumpulanVideoPage> {
  late Future<List<dynamic>> _videoList;

  Future<List<dynamic>> fetchVideo() async {
    final response = await http.get(Uri.parse('${dotenv.env['URL']}/video'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Gagal memuat data edukasi video');
    }
  }

  String formatDate(String dateStr) {
    final dateTime = DateTime.parse(dateStr);
    return DateFormat('d MMMM yyyy', 'id_ID').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    _videoList = fetchVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edukasi Video',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white, // <-- Ubah biar kontras
            fontSize: 22,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _videoList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          }

          final videoList = snapshot.data!;

          return Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),

                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: videoList.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio:
                              0.75, // Sesuaikan dengan tinggi/lebar VideoCard
                        ),
                    itemBuilder: (context, index) {
                      final edukasiVideo = videoList[index];
                      return VideoCard(
                        imageUrl: edukasiVideo['thumbnail_url'] ?? '',
                        title: edukasiVideo['judul_video'],
                        date: formatDate(edukasiVideo['created_at']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PetugasDetailVideoPage(
                                    videoId: edukasiVideo['id'],
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
          );
        },
      ),
    );
  }
}
