import 'package:flutter/material.dart';
import 'package:mobile_ta/pages/petugas/info_page.dart';
import 'package:mobile_ta/pages/petugas/notifikasi_page.dart';
import 'package:mobile_ta/pages/petugas/petugas_edit_profil_page.dart';
import 'package:mobile_ta/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../auth/login_page.dart';
import 'package:google_fonts/google_fonts.dart';

class PetugasAkunPage extends StatelessWidget {
  final Map<String, dynamic>? akunData;
  final Map<String, dynamic>? profilData;
  const PetugasAkunPage({Key? key, this.akunData, this.profilData})
    : super(key: key);

  Future<void> logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Akun Saya",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(16)),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      (profilData?['gambar_pengguna'] ?? '').isNotEmpty
                          ? profilData!['gambar_url']
                          : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg',
                    ),
                  ),
                  SizedBox(height: 8),

                  //username
                  Text(
                    akunData?['username'] ?? 'Memuat...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  //email
                  Text(
                    akunData?['email'] ?? 'Memuat...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 16),
                  SizedBox(
                    width: 160,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PetugasEditProfilPage(
                                  profilData: profilData,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF128d54),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        shadowColor: Colors.green.withOpacity(0.15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Edit Akun",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            //menu menu
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.20),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      Icons.info,
                      "Info",
                      iconColor: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PetugasInfoPage()),
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    _buildMenuItem(
                      Icons.mail_outline,
                      "Notifikasi",
                      iconColor: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetugasNotifikasiPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    _buildMenuItem(
                      Icons.logout,
                      "Logout",
                      iconColor: Colors.white,
                      onTap: () => logout(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //widget builder
  Widget _buildMenuItem(
    IconData icon,
    String title, {
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff15a864), Color(0xFF128d54)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? Colors.white),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.white,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
