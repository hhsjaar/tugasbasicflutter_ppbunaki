import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/warga/akun_page.dart';
import 'package:mobile_ta/pages/warga/edukasi_page.dart';
import 'package:mobile_ta/pages/warga/setor_page.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../pages/warga/beranda_page.dart';
import '../pages/warga/tambah_profil_page.dart';

class WargaMainWrapper extends StatefulWidget {
  final int initialMenu;
  const WargaMainWrapper({Key? key, this.initialMenu = 0}) : super(key: key);

  @override
  State<WargaMainWrapper> createState() => _WargaMainWrapperState();
}

class _WargaMainWrapperState extends State<WargaMainWrapper> {
  int selectedMenu = 0;
  Map<String, dynamic>? akunData;
  Map<String, dynamic>? profilData;
  Map<String, dynamic>? saldoData;

  List<dynamic> artikelList = [];
  List<dynamic> videoList = [];

  double? totalSampah;

  @override
  void initState() {
    super.initState();
    selectedMenu = widget.initialMenu;
    checkInitialData();
  }

  Future<void> loadAkunData() async {
    final data = await fetchAkunData();
    setState(() {
      akunData = data;
    });
  }

  Future<void> loadTotalSampah() async {
    // Mock total sampah
    setState(() {
      totalSampah = 150.5;
    });
  }

  Future<void> loadSaldoData() async {
    final data = await fetchSaldoData();
    setState(() {
      saldoData = data;
    });
  }

  bool isLoading = true;
  bool profilDitemukan = false;

  Future<void> checkInitialData() async {
    await loadAkunData();

    await cekProfil();
    // Jika profil ditemukan, baru load saldo
    if (profilDitemukan) {
      await loadSaldoData();
      await loadArtikel();
      await loadVideo();
      await loadTotalSampah();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadArtikel() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/artikel/terbaru'),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          artikelList = jsonData['data'];
        });
      }
    } catch (e) {
      debugPrint('Gagal load artikel: $e');
    }
  }

  Future<void> loadVideo() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/video/terbaru'),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          videoList = jsonData['data'];
        });
      }
    } catch (e) {
      debugPrint('Gagal load video: $e');
    }
  }

  Future<void> cekProfil() async {
    // Mock profil
    setState(() {
      profilDitemukan = true;
      profilData = {
        'id': 1,
        'nama': 'Mock Warga',
        'alamat': 'Jl. Mock No. 1',
        'no_hp': '08123456789',
      };
    });
  }

  Future<Map<String, dynamic>?> fetchAkunData() async {
    // Mock akun data
    return {
      'id': 1,
      'name': 'Mock Warga',
      'username': 'warga',
      'email': 'warga@mock.com',
    };
  }

  Future<Map<String, dynamic>?> fetchSaldoData() async {
    // Mock saldo data
    return {
      'saldo': 50000,
      'total_setor': 200.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!profilDitemukan) {
      return const WargaTambahProfilPage(); // redirect ke tambah profil jika tidak ditemukan
    }

    List<Widget> menu = [
      WargaBerandaPage(
        akunData: akunData,
        profilData: profilData,
        saldoData: saldoData,
        artikelList: artikelList,
        videoList: videoList,
        totalSampah: totalSampah?.toString(),
      ),
      WargaSetorPage(profilData: profilData),
      WargaEdukasiPage(
        akunData: akunData,
        artikelList: artikelList,
        videoList: videoList,
      ),
      WargaAkunPage(
        akunData: akunData,
        profilData: profilData,
        saldoData: saldoData,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: menu.elementAtOrNull(selectedMenu),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedMenu,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.grey.shade200,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            selectedMenu = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.recycling), label: 'Setor'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Edukasi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}
