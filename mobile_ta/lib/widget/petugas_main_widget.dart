import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/petugas/petugas_akun_page.dart';
import 'package:mobile_ta/pages/petugas/petugas_konten_page.dart';
import 'package:mobile_ta/pages/petugas/petugas_setor_page.dart';
import 'package:mobile_ta/services/auth_service.dart';
import '../pages/petugas/beranda_page.dart';
import '../pages/petugas/petugas_tambah_profil_page.dart';

class PetugasMainWrapper extends StatefulWidget {
  final int initialMenu;
  const PetugasMainWrapper({Key? key, this.initialMenu = 0}) : super(key: key);

  @override
  State<PetugasMainWrapper> createState() => _WargaMainWrapperState();
}

class _WargaMainWrapperState extends State<PetugasMainWrapper> {
  int selectedMenu = 0;
  Map<String, dynamic>? akunData;
  Map<String, dynamic>? profilData;
  List<dynamic> artikelList = [];
  List<dynamic> videoList = [];
  List<dynamic> setorTerbaruList = [];

  String? totalSampah;
  String? totalSampahBotol;

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

  bool isLoading = true;
  bool profilDitemukan = false;

  Future<void> checkInitialData() async {
    await loadAkunData();
    await cekProfil();
    if (profilDitemukan) {
      await loadArtikel();
      await loadVideo();
      await loadSetorTerbaru();
      await loadTotalSampah();
      await loadTotalSampahBotol();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadTotalSampah() async {
    // Mock total sampah
    setState(() {
      totalSampah = '150.5';
    });
  }

  Future<void> loadTotalSampahBotol() async {
    // Mock total sampah botol
    setState(() {
      totalSampahBotol = '50.0';
    });
  }

  Future<void> loadArtikel() async {
    // Mock artikel
    setState(() {
      artikelList = [
        {
          'id': 1,
          'title': 'Artikel Mock 1',
          'content': 'Konten artikel mock.',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'title': 'Artikel Mock 2',
          'content': 'Konten artikel mock kedua.',
          'created_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        },
      ];
    });
  }

  Future<void> loadVideo() async {
    // Mock video
    setState(() {
      videoList = [
        {
          'id': 1,
          'title': 'Video Mock 1',
          'url': 'https://example.com/video1.mp4',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'title': 'Video Mock 2',
          'url': 'https://example.com/video2.mp4',
          'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        },
      ];
    });
  }

  Future<void> loadSetorTerbaru() async {
    // Mock setor terbaru
    setState(() {
      setorTerbaruList = [
        {
          'id': 1,
          'warga_name': 'Warga Mock 1',
          'berat': 10.5,
          'tanggal': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'warga_name': 'Warga Mock 2',
          'berat': 5.0,
          'tanggal': DateTime.now().subtract(Duration(hours: 3)).toIso8601String(),
        },
      ];
    });
  }

  Future<void> cekProfil() async {
    // Mock profil
    setState(() {
      profilDitemukan = true;
      profilData = {
        'id': 1,
        'nama': 'Mock Petugas',
        'alamat': 'Jl. Mock No. 1',
        'no_hp': '08123456789',
      };
    });
  }

  Future<Map<String, dynamic>?> fetchAkunData() async {
    // Mock akun data
    return {
      'id': 1,
      'name': 'Mock Petugas',
      'username': 'petugas',
      'email': 'petugas@mock.com',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!profilDitemukan) {
      return const PetugasTambahProfilPage(); // redirect ke tambah profil jika tidak ditemukan
    }
    List menu = [
      PetugasBerandaPage(
        akunData: akunData,
        profilData: profilData,
        artikelList: artikelList,
        videoList: videoList,
        setorTerbaruList: setorTerbaruList,
        totalSampah: totalSampah,
        totalSampahBotol: totalSampahBotol,
      ),
      PetugasSetorPage(),
      PetugasKontenPage(artikelList: artikelList, videoList: videoList),
      PetugasAkunPage(akunData: akunData, profilData: profilData),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: menu[selectedMenu],
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
