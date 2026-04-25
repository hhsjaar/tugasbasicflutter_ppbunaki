import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';

class WargaDetailArtikelPage extends StatefulWidget {
  final int id;

  const WargaDetailArtikelPage({super.key, required this.id});

  @override
  State<WargaDetailArtikelPage> createState() => _WargaDetailArtikelPageState();
}

class _WargaDetailArtikelPageState extends State<WargaDetailArtikelPage> {
  Map<String, dynamic>? artikel;

  Future<void> fetchArtikelDetail() async {
    final response = await http.get(
      Uri.parse('${dotenv.env['URL']}/artikel/${widget.id}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      setState(() {
        artikel = data;
      });
    } else {
      throw Exception('Gagal memuat detail artikel');
    }
  }

  String formatTanggal(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  @override
  void initState() {
    super.initState();
    fetchArtikelDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edukasi Artikel',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      body:
          artikel == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gambar Artikel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        artikel!['gambar_url'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Judul
                    Text(
                      artikel!['judul_artikel'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF128d54),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Info Author dan Tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          artikel!['nama_author'],
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatTanggal(artikel!['created_at']),
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Deskripsi HTML
                    Html(
                      data: artikel!['deskripsi_artikel'],
                      style: {
                        "div": Style(
                          fontSize: FontSize(16.0),
                          lineHeight: LineHeight(1.6),
                          textAlign: TextAlign.justify,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                        "strong": Style(fontWeight: FontWeight.bold),
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
