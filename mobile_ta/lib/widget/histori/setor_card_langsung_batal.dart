import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoriSetorCardLangsungBatal extends StatelessWidget {
  final Map<String, dynamic> data;
  const HistoriSetorCardLangsungBatal({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final waktuPengajuan = data['waktu_pengajuan'];
    final catatan = data['catatan_petugas'];
    final tanggal =
        waktuPengajuan != null
            ? DateFormat(
              'EEEE, dd-MM-yyyy',
              'id_ID',
            ).format(DateTime.parse(waktuPengajuan))
            : "-";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Setor Langsung",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF128d54),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tanggal,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                if (catatan != null && catatan.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Catatan: $catatan",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.cancel, color: Colors.redAccent),
        ],
      ),
    );
  }
}
