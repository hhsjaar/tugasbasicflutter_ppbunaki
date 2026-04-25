import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotifikasiCard extends StatelessWidget {
  final String title;
  final String date;
  final String body;

  const NotifikasiCard({
    super.key,
    required this.title,
    required this.date,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: width * 0.95,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF128d54),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.notifications_active, color: Color(0xFF128d54)),
        ],
      ),
    );
  }
}
