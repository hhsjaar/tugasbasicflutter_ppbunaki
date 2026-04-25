import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ta/services/notifikasi_petugas_service.dart';
import '../../models/notification_model.dart';
import 'package:mobile_ta/widget/notifikasi_card.dart';

class PetugasNotifikasiPage extends StatelessWidget {
  const PetugasNotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          'Notifikasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: FutureBuilder<List<NotificationModel>>(
          future: NotifikasiPetugasService().fetchNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 8),
                    Text('Gagal memuat notifikasi'),
                  ],
                ),
              );
            }

            final notifs = snapshot.data ?? [];

            if (notifs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.notifications_off, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text('Belum ada notifikasi'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: notifs.length,
              itemBuilder: (context, index) {
                final notif = notifs[index];
                return NotifikasiCard(
                  title: notif.title,
                  date: DateFormat('dd/MM/yyyy – HH:mm').format(notif.createdAt),
                  body: notif.body,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
