import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_ta/pages/petugas/artikel/petugas_detail_artikel_page.dart';
import 'package:mobile_ta/widget/eduCard_widget.dart';

class PetugasKumpulanArtikelPage extends StatefulWidget {
  const PetugasKumpulanArtikelPage({super.key});

  @override
  State<PetugasKumpulanArtikelPage> createState() =>
      _PetugasKumpulanArtikelPageState();
}

class _PetugasKumpulanArtikelPageState
    extends State<PetugasKumpulanArtikelPage> {
  late Future<List<dynamic>> _artikelList;

  Future<List<dynamic>> fetchArtikel() async {
    final response = await http.get(Uri.parse('${dotenv.env['URL']}/artikel'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Gagal memuat data artikel');
    }
  }

  String formatDate(String dateStr) {
    final dateTime = DateTime.parse(dateStr);
    return DateFormat('d MMMM yyyy', 'id_ID').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    _artikelList = fetchArtikel();
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
          'Edukasi Artikel',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _artikelList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          }

          final artikelList = snapshot.data!;

          return Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Kumpulan Artikel Edukasi",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF128d54),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: artikelList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final artikel = artikelList[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.10),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: EduCard(
                            imageUrl: artikel['gambar_url'],
                            title: artikel['judul_artikel'],
                            date: formatDate(artikel['created_at']),
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
