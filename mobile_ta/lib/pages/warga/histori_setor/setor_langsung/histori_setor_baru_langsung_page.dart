import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/warga/detail_map/map_bank_sampah_page.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoriSetorBaruLangsungPage extends StatefulWidget {
  final int id;
  final String tanggal;
  final String catatan;
  const HistoriSetorBaruLangsungPage({
    required this.id,
    required this.tanggal,
    required this.catatan,
    super.key,
  });

  @override
  State<HistoriSetorBaruLangsungPage> createState() =>
      _HistoriSetorBaruLangsungPageState();
}

class _HistoriSetorBaruLangsungPageState
    extends State<HistoriSetorBaruLangsungPage> {
  Map<String, dynamic>? bankSampah;
  String namaBank = 'Memuat...';
  String deskripsiBank = 'Memuat...';
  String alamatBank = 'Memuat...';
  String namaAdmin = 'Memuat...';
  String emailAdmin = 'Memuat...';
  String noHpAdmin = 'Memuat...';
  double? latitudeBankSampah;
  double? longitudeBankSampah;
  GoogleMapController? _mapController;
  CameraPosition? _initialCameraPosition;
  Set<Marker> _markers = {};

  bool isLoading = false;
  String? formattedDate;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      await fetchBankSampah();
      await _updateBankData();
      _updateMarkers();
    } catch (e) {
      debugPrint('Error in fetchData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data bank sampah')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _updateBankData() async {
    if (bankSampah == null) return;

    setState(() {
      namaBank = bankSampah?['nama_bank_sampah'] ?? 'Tidak tersedia';
      deskripsiBank = bankSampah?['deskripsi_bank_sampah'] ?? 'Tidak tersedia';
      alamatBank = bankSampah?['alamat_bank_sampah'] ?? 'Tidak tersedia';
      namaAdmin =
          bankSampah?['user']?['profil']?['nama_pengguna'] ?? 'Tidak tersedia';
      emailAdmin = bankSampah?['user']?['email'] ?? 'Tidak tersedia';
      noHpAdmin =
          bankSampah?['user']?['profil']?['no_hp_pengguna'] ?? 'Tidak tersedia';

      // Parse coordinates with better error handling
      latitudeBankSampah = _parseCoordinate(bankSampah?['latitude']);
      longitudeBankSampah = _parseCoordinate(bankSampah?['longitude']);

      if (latitudeBankSampah != null && longitudeBankSampah != null) {
        _initialCameraPosition = CameraPosition(
          target: LatLng(latitudeBankSampah!, longitudeBankSampah!),
          zoom: 15,
        );
      }
    });
  }

  double? _parseCoordinate(dynamic coordinate) {
    if (coordinate == null) return null;
    if (coordinate is double) return coordinate;
    if (coordinate is int) return coordinate.toDouble();
    if (coordinate is String) return double.tryParse(coordinate);
    return null;
  }

  void _updateMarkers() {
    if (latitudeBankSampah == null || longitudeBankSampah == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('bank_sampah_location'),
          position: LatLng(latitudeBankSampah!, longitudeBankSampah!),
          infoWindow: InfoWindow(title: namaBank),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });

    // Move camera after a slight delay to ensure map is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(latitudeBankSampah!, longitudeBankSampah!),
        ),
      );
    });
  }

  Future<Map<String, dynamic>?> fetchBankSampah() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/bank-sampah'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          if (mounted) {
            setState(() {
              bankSampah = responseData['data'];
            });
          }
          return responseData['data'];
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          return await fetchBankSampah();
        }
      } else {
        debugPrint('Gagal ambil data bank sampah: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetch bank sampah: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF128d54)),
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 18),
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
                            'Detail Setor Langsung',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Berikut detail penyetoran dan informasi bank sampah.',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.10),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Detail Penyetoran",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF128d54),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tanggal: ${widget.tanggal}",
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            "Catatan: ${widget.catatan.isNotEmpty ? widget.catatan : "-"}",
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.10),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Informasi Bank Sampah",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF128d54),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Nama: $namaBank",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Deskripsi: $deskripsiBank",
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Alamat: $alamatBank",
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 12),
                          _buildMapImage(),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  latitudeBankSampah != null &&
                                          longitudeBankSampah != null
                                      ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    WargaMapBankSampahPage(
                                                      latitude:
                                                          latitudeBankSampah!,
                                                      longitude:
                                                          longitudeBankSampah!,
                                                      namaBank: namaBank,
                                                    ),
                                          ),
                                        );
                                      }
                                      : null,
                              icon: const Icon(Icons.map),
                              label: Text(
                                "Detail Map",
                                style: GoogleFonts.poppins(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF128d54),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.10),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Kontak Admin",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF128d54),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Nama: $namaAdmin",
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            "Email: $emailAdmin",
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            "No HP: $noHpAdmin",
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  Widget _buildMapImage() {
    // Check if coordinates are valid
    if (latitudeBankSampah == null ||
        longitudeBankSampah == null ||
        _initialCameraPosition == null) {
      return _buildFallbackMapImage();
    }

    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition!,
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
            // After map is created, move to bank sampah position
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(latitudeBankSampah!, longitudeBankSampah!),
              ),
            );
          },
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }

  Widget _buildFallbackMapImage() {
    return Image.network(
      "https://i.pinimg.com/736x/b0/79/09/b079096855c0edbaba47d93c67f18853.jpg",
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
