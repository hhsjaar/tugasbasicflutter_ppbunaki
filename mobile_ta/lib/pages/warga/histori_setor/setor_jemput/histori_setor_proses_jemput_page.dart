import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/warga/detail_map/map_bank_sampah_map_warga_page.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoriSetorProsesJemputPage extends StatefulWidget {
  final int id;
  final String tanggal;
  final String catatan;
  const HistoriSetorProsesJemputPage({
    required this.id,
    required this.tanggal,
    required this.catatan,
    super.key,
  });

  @override
  State<HistoriSetorProsesJemputPage> createState() =>
      HistoriSetorProsesJemputPageState();
}

class HistoriSetorProsesJemputPageState
    extends State<HistoriSetorProsesJemputPage> {
  Map<String, dynamic>? profilData;
  Map<String, dynamic>? bankSampah;
  Map<String, dynamic>? pengajuanDetailSetor;

  Map<int, Map<String, dynamic>> jenisSampahCache = {};
  bool isLoading = true;

  late double latitudeBankSampah;
  late double longitudeBankSampah;
  late double latitudeWarga;
  late double longitudeWarga;
  late GoogleMapController _mapController;
  late CameraPosition _initialCameraPosition;
  Set<Marker> _markers = {};

  List<Map<String, dynamic>> processedSetoran = [];
  int ongkir_per_jarak = 0;
  double totalBerat = 0;
  int totalHarga = 0;
  int biayaLayanan = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await fetchPengajuanDetailSetor();
      await fetchJenisSampah();
      await fetchBankSampah();

      if (pengajuanDetailSetor != null && bankSampah != null) {
        final profil = pengajuanDetailSetor!['user']?['profil'];

        // Parse coordinates with proper error handling
        latitudeWarga =
            double.tryParse(profil?['latitude']?.toString() ?? '0') ?? 0;
        longitudeWarga =
            double.tryParse(profil?['longitude']?.toString() ?? '0') ?? 0;
        latitudeBankSampah =
            double.tryParse(bankSampah?['latitude']?.toString() ?? '0') ?? 0;
        longitudeBankSampah =
            double.tryParse(bankSampah?['longitude']?.toString() ?? '0') ?? 0;
        ongkir_per_jarak = bankSampah?['ongkir_per_jarak'] ?? 0;

        // Calculate mid point for initial camera position
        final midLat = (latitudeBankSampah + latitudeWarga) / 2;
        final midLng = (longitudeBankSampah + longitudeWarga) / 2;

        _initialCameraPosition = CameraPosition(
          target: LatLng(midLat, midLng),
          zoom: 12,
        );

        // Process setoran data
        final detailSetoran = pengajuanDetailSetor!['input_detail'];
        final setoranSampah = detailSetoran['setoran_sampah'] as List;

        // Reset totals
        totalBerat = 0;
        totalHarga = 0;
        biayaLayanan = 0;

        processedSetoran =
            setoranSampah.map((item) {
              final jenisId = item['jenis_sampah_id'];
              final berat = (item['berat'] as num).toDouble();
              final jenisInfo = jenisSampahCache[jenisId];
              final subtotal = (berat * (jenisInfo?['harga'] ?? 0)).round();

              totalBerat += berat;
              totalHarga += subtotal;

              return {
                'nama': jenisInfo?['nama'] ?? 'Unknown',
                'berat': berat,
                'subtotal': subtotal,
                'warna': jenisInfo?['warna'] ?? '#999999',
              };
            }).toList();
      }

      calculateServiceFee();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _updateMarkers();
        });
      }
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('warga_location'),
          position: LatLng(latitudeWarga, longitudeWarga),
          infoWindow: const InfoWindow(title: 'Lokasi Warga'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: const MarkerId('bank_sampah_location'),
          position: LatLng(latitudeBankSampah, longitudeBankSampah),
          infoWindow: InfoWindow(
            title: bankSampah?['nama_bank_sampah'] ?? 'Bank Sampah',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };

      // Fit camera to show both markers
      if (_mapController != null) {
        final bounds = _getBounds();
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      }
    });
  }

  LatLngBounds _getBounds() {
    final northeast = LatLng(
      latitudeBankSampah > latitudeWarga ? latitudeBankSampah : latitudeWarga,
      longitudeBankSampah > longitudeWarga
          ? longitudeBankSampah
          : longitudeWarga,
    );
    final southwest = LatLng(
      latitudeBankSampah < latitudeWarga ? latitudeBankSampah : latitudeWarga,
      longitudeBankSampah < longitudeWarga
          ? longitudeBankSampah
          : longitudeWarga,
    );
    return LatLngBounds(northeast: northeast, southwest: southwest);
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

  Future<void> fetchPengajuanDetailSetor() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/setor-jemput/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            pengajuanDetailSetor = jsonDecode(response.body)['data'];
          });
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await fetchPengajuanDetailSetor();
        }
      }
    } catch (e) {
      debugPrint('Error fetch pengajuan detail setor: $e');
    }
  }

  Future<void> fetchJenisSampah() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null || pengajuanDetailSetor == null) {
      debugPrint('Token tidak ditemukan atau data pengajuan kosong');
      return;
    }

    try {
      final setoran =
          pengajuanDetailSetor!['input_detail']['setoran_sampah'] ?? [];

      for (var item in setoran) {
        final int jenisId = item['jenis_sampah_id'];
        if (!jenisSampahCache.containsKey(jenisId)) {
          final response = await http.get(
            Uri.parse('${dotenv.env['URL']}/jenis-sampah/$jenisId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body)['data'];
            jenisSampahCache[jenisId] = {
              'nama': data['nama_sampah'],
              'harga': data['harga_per_satuan'],
              'warna': data['warna_indikasi'],
            };
          } else if (response.statusCode == 401) {
            final refreshed = await authService.refreshToken();
            if (refreshed) {
              await fetchJenisSampah(); // Retry the whole function
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetch jenis sampah: $e');
    }
  }

  int _calculateDistanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // Radius bumi dalam kilometer
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return distance < 1 ? 0 : distance.round();
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return "Kurang dari 1 Km";
    } else {
      return "${distance.round()} km";
    }
  }

  void calculateServiceFee() {
    if (longitudeWarga == null) {
      biayaLayanan = 0;
      return;
    }

    final jarak = _calculateDistanceInKm(
      latitudeWarga,
      longitudeWarga,
      latitudeBankSampah,
      longitudeBankSampah,
    );

    biayaLayanan = jarak * ongkir_per_jarak;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || pengajuanDetailSetor == null || bankSampah == null) {
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
            "Histori Setor Jemput",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Color(0xFF128d54),
              fontSize: 22,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          'Setor Jemput',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                    'Detail Setor Jemput',
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
                    "Komposisi Sampah",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF128d54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[300],
                        ),
                      ),
                      Row(
                        children:
                            processedSetoran.map((item) {
                              final double proportion =
                                  item['berat'] / totalBerat;
                              return Expanded(
                                flex: (proportion * 1000).round(),
                                child: Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _parseHexColor(item['warna']),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${totalBerat.toStringAsFixed(1)} kg',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...processedSetoran.map((item) {
                    return Row(
                      children: [
                        Icon(
                          Icons.square,
                          color: _parseHexColor(item['warna']),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['nama'],
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        Text(
                          '${item['berat']} kg',
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Rp${item['subtotal']}',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    );
                  }).toList(),
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
                    'Estimasi Insentif',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF128d54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimasi harga sampah anda',
                        style: GoogleFonts.poppins(),
                      ),
                      Text('Rp $totalHarga', style: GoogleFonts.poppins()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Jarak", style: GoogleFonts.poppins()),
                      Text(
                        _formatDistance(
                          _calculateDistanceInKm(
                            latitudeWarga,
                            longitudeWarga,
                            latitudeBankSampah,
                            longitudeBankSampah,
                          ).toDouble(),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Biaya Layanan (Ongkir)",
                        style: GoogleFonts.poppins(),
                      ),
                      Text('Rp $biayaLayanan', style: GoogleFonts.poppins()),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Perkiraan Insentif',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${totalHarga - biayaLayanan}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ],
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
                    "Nama: ${bankSampah?['nama_bank_sampah'] ?? '-'}",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Alamat: ${bankSampah?['alamat'] ?? '-'}",
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  _buildMapImage(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => WargaMapBankSampahMapWargaPage(
                                  latitudeWarga: latitudeWarga,
                                  longitudeWarga: longitudeWarga,
                                  latitudeBankSampah: latitudeBankSampah,
                                  longitudeBankSampah: longitudeBankSampah,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: Text("Detail Map", style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF128d54),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse(hexColor, radix: 16));
  }

  Widget _buildMapImage() {
    // Check if coordinates are valid
    if (latitudeWarga == 0 ||
        longitudeWarga == 0 ||
        latitudeBankSampah == 0 ||
        longitudeBankSampah == 0) {
      return _buildFallbackMapImage();
    }

    return SizedBox(
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
            // After map is created, fit the bounds
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final bounds = _getBounds();
              _mapController.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 50.0),
              );
            });
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
}
