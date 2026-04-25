import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_ta/pages/warga/setor_langsung/detail_page.dart';

class WargaSetorLangsung extends StatefulWidget {
  const WargaSetorLangsung({super.key});

  @override
  State<WargaSetorLangsung> createState() => _WargaSetorLangsungState();
}

class _WargaSetorLangsungState extends State<WargaSetorLangsung> {
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF128d54)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Setor Langsung',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
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
            const SizedBox(height: 24),

            Text(
              "Tanggal Penyetoran",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF128d54),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Color(0xFF8fd14f).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextFormField(
                controller: _tanggalController,
                readOnly: true,
                style: GoogleFonts.poppins(fontSize: 15),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
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
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "Catatan Petugas (Opsional)",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF128d54),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFF8fd14f).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextFormField(
                controller: _catatanController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.poppins(fontSize: 15),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Masukkan catatan untuk petugas...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFB2DFDB)),
              ),
              child: Text(
                "Anda hanya dapat melakukan satu kali booking penyetoran. Gunakan tombol 'Ubah' untuk mengganti waktu, atau 'Batalkan' jika ingin membatalkan layanan.",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => WargaDetailSetorLangsung(
                            tanggal: _tanggalController.text,
                            catatan:
                                _catatanController.text.isNotEmpty
                                    ? _catatanController.text
                                    : null,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF128d54),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Selanjutnya",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
