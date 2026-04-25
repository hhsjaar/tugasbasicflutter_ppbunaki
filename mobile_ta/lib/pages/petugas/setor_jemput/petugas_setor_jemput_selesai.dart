import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/petugas/detail_map/map_bank_sampah_map_warga_page.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/widget/petugas_main_widget.dart';

class PetugasSetorJemputSelesai extends StatefulWidget {
  final int id;
  const PetugasSetorJemputSelesai({required this.id, super.key});

  @override
  State<PetugasSetorJemputSelesai> createState() =>
      _PetugasSetorJemputSelesaiState();
}

class _PetugasSetorJemputSelesaiState extends State<PetugasSetorJemputSelesai> {
  Map<String, dynamic>? pengajuanDetailSetor;
  Map<String, dynamic>? bankSampah;
  Map<int, Map<String, dynamic>> jenisSampahCache = {};

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
  String gambarPengguna = '';
  String namaPengguna = 'memuat';
  String alamatPengguna = 'memuat';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchPengajuanDetailSetor();
    await fetchJenisSampah();
    await fetchBankSampah();

    if (pengajuanDetailSetor != null && bankSampah != null) {
      final profil = pengajuanDetailSetor!['user']?['profil'];

      final inputDetail = pengajuanDetailSetor!['input_detail'];

      // Update class variables instead of creating new ones
      gambarPengguna =
          (profil != null && (profil['gambar_pengguna'] ?? '').isNotEmpty)
              ? profil['gambar_url']
              : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg';

      namaPengguna = profil?['nama_pengguna'] ?? 'memuat..';
      alamatPengguna = profil?['alamat_pengguna'] ?? 'memuat..';

      // Parse coordinates with proper error handling
      latitudeWarga =
          double.tryParse(inputDetail?['latitude']?.toString() ?? '0') ?? 0;
      longitudeWarga =
          double.tryParse(inputDetail?['longitude']?.toString() ?? '0') ?? 0;
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
            final harga =
                item['harga'] as int; // Ambil harga langsung dari data setoran
            final jenisInfo = jenisSampahCache[jenisId];
            final subtotal =
                (berat * harga).round(); // Gunakan harga dari setoran

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
    setState(() {
      isLoading = false;
      _updateMarkers();
    });
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
        Uri.parse('${dotenv.env['URL']}/setor-jemput/selesai/${widget.id}'),
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
          await fetchPengajuanDetailSetor(); // Retry after refresh
        }
      }
    } catch (e) {
      debugPrint('Error in fetchPengajuanDetailSetor: $e');
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
              await fetchJenisSampah(); // Retry entire function
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error in fetchJenisSampah: $e');
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

  Widget build(BuildContext context) {
    if (isLoading || pengajuanDetailSetor == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Setor Sampah Jemput")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => PetugasMainWrapper(initialMenu: 1),
                ),
                (Route<dynamic> route) => false,
              ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Setor Jemput",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Selesai",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Penyetor
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.25),
                    blurRadius: 8,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(gambarPengguna),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    namaPengguna,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
            // Estimasi Berat
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                "Estimasi Berat Sampah",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 8),
            // Kartu Estimasi
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                      ),
                      Row(
                        children:
                            processedSetoran.map((item) {
                              final proportion = item['berat'] / totalBerat;
                              return Expanded(
                                flex: (proportion * 1000).round(),
                                child: Container(
                                  height: 32,
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
                            "${totalBerat.toStringAsFixed(1)}kg",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...processedSetoran.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.square,
                            color: _parseHexColor(item['warna']),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['nama'],
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          Text(
                            "${item['berat']}kg",
                            style: GoogleFonts.poppins(),
                          ),
                          SizedBox(width: 16),
                          Text(
                            "Rp${item['subtotal']}",
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                "Estimasi Harga Sampah",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            // Estimasi Insentif
            Container(
              padding: const EdgeInsets.all(16),
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
                            latitudeWarga ?? 0,
                            longitudeWarga ?? 0,
                            latitudeBankSampah ?? 0,
                            longitudeBankSampah ?? 0,
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
                      Text('Rp $biayaLayanan'),
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
            SizedBox(height: 16),
            // const SizedBox(height: 16),
            Container(
              // margin: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Alamat Warga",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    alamatPengguna,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            _buildMapImage(),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => (PetugasMapBankSampahMapWargaPage(
                            latitudeWarga: latitudeWarga,
                            longitudeWarga: longitudeWarga,
                            latitudeBankSampah: latitudeBankSampah,
                            longitudeBankSampah: longitudeBankSampah,
                            namaPengguna: namaPengguna,
                          )),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: Text(
                  "Detail Map",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF128d54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
