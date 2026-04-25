import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ta/pages/petugas/setor_jemput/petugas_setor_jemput_selesai.dart';

class SetorCardJemputSelesai extends StatelessWidget {
  final Map<String, dynamic> data;
  const SetorCardJemputSelesai({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final waktuPengajuan = data['waktu_pengajuan'];
    final tanggal =
        waktuPengajuan != null
            ? DateFormat(
              'EEEE, dd-MM-yyyy',
              'id_ID',
            ).format(DateTime.parse(waktuPengajuan))
            : "-";

    final profil = data['user']?['profil'];
    final gambarPengguna =
        (profil != null && (profil['gambar_pengguna'] ?? '').isNotEmpty)
            ? profil['gambar_url']
            : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg';

    final namaPengguna = profil['nama_pengguna'] ?? 'memuat..';

    return Container(
      width: width * 0.95,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1a9f61), Color(0xFF128d54)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: width * 0.07,
            backgroundImage: NetworkImage(gambarPengguna),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaPengguna,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Setor Jemput",
                  style: TextStyle(fontSize: width * 0.04, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Text(
                tanggal,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              PetugasSetorJemputSelesai(id: data['id']),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
