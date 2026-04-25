import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_ta/pages/warga/histori_saldo/detail_histori_saldo_page.dart';

class TarikSaldoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const TarikSaldoCard({required this.data, super.key});

  String formatCurrency(int amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return Colors.orange;
      case 'terima':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  String formatMetode(String metode) {
    final lower = metode.toLowerCase();
    if (lower == 'dana' || lower == 'shopeepay') {
      return 'E-Wallet (${_capitalize(metode)})';
    } else if (lower == 'bni' || lower == 'bca') {
      return 'Transfer Bank (${metode.toUpperCase()})';
    }
    return _capitalize(metode);
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final int jumlah = data['jumlah_saldo'];
    final status = data['status'] ?? '';
    final metode = data['metode'] ?? '';
    final tanggal = data['tanggal_format'] ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
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
                  formatCurrency(jumlah),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF128d54),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: getStatusColor(status),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMetode(metode),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tanggal,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF128d54)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailHistoriSaldoPage(id: data['id']),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
