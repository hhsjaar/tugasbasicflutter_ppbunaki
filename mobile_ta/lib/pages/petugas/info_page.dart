import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PetugasInfoPage extends StatelessWidget {
  const PetugasInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Info Aplikasi',
          style: GoogleFonts.poppins(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Tentang Aplikasi',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF128d54),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aplikasi Bank Sampah adalah solusi digital yang memudahkan warga dalam melakukan penyetoran sampah kepada petugas bank sampah.',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            'Terdapat dua metode penyetoran sampah:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "• Setor Langsung: Warga membawa sampah ke lokasi bank sampah.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          Text(
            "• Setor Jemput: Petugas akan menjemput sampah dari rumah warga.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 24),

          Text(
            'Fitur Utama',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF128d54),
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.home,
            'Beranda',
            'Menampilkan informasi dan status terbaru.',
          ),
          _buildFeatureItem(
            Icons.recycling,
            'Setor Sampah',
            'Ajukan setor sampah secara langsung atau dijemput.',
          ),
          _buildFeatureItem(
            Icons.article,
            'Edukasi Artikel',
            'Baca artikel tentang pengelolaan sampah.',
          ),
          _buildFeatureItem(
            Icons.ondemand_video,
            'Edukasi Video',
            'Tonton video edukatif tentang lingkungan.',
          ),
          _buildFeatureItem(
            Icons.account_circle,
            'Akun',
            'Kelola profil dan pengaturan akun Anda.',
          ),
          const SizedBox(height: 24),

          Text(
            'Cara Penggunaan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF128d54),
            ),
          ),
          const SizedBox(height: 12),
          _buildStepItem(1, 'Masuk ke aplikasi menggunakan akun Anda.'),
          _buildStepItem(2, 'Buka menu "Setor Sampah" di halaman utama.'),
          _buildStepItem(3, 'Pilih jenis setor: langsung atau jemput.'),
          _buildStepItem(4, 'Isi detail pengajuan dan kirim.'),
          _buildStepItem(
            5,
            'Pantau status pengajuan melalui menu "histori" pada beranda.',
          ),
          _buildStepItem(
            6,
            'Setelah statusnya selesai maka saldo akan terisi otomatis',
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              "Versi Aplikasi: 1.0.0",
              style: GoogleFonts.poppins(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(icon, color: Color(0xFF128d54)),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle, style: GoogleFonts.poppins()),
    );
  }

  Widget _buildStepItem(int number, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. ",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(description, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }
}
