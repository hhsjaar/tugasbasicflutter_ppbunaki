import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/petugas/detail_map/map_bank_sampah_map_warga_page.dart';
import 'package:mobile_ta/pages/petugas/setor_jemput/petugas_setor_jemput_proses.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/widget/petugas_main_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class PetugasSetorJemputBaru extends StatefulWidget {
  final int id;
  final String tanggal;
  final String catatan;
  const PetugasSetorJemputBaru({
    required this.id,
    required this.tanggal,
    required this.catatan,
    super.key,
  });

  @override
  State<PetugasSetorJemputBaru> createState() => _PetugasSetorJemputBaruState();
}

class _PetugasSetorJemputBaruState extends State<PetugasSetorJemputBaru> {
  Map<String, dynamic>? pengajuanDetailSetor;
  Map<String, dynamic>? bankSampah;
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
  String gambarPengguna = '';
  String namaPengguna = 'memuat..';
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

        gambarPengguna =
            (profil != null && (profil['gambar_url'] ?? '').isNotEmpty)
                ? profil['gambar_url']
                : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg';

        namaPengguna = profil?['nama_pengguna'] ?? 'memuat..';

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

  Future<void> ambilSetoran() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse(
          '${dotenv.env['URL']}/setor-jemput/terima-pengajuan/${widget.id}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PetugasSetorJemputProses(id: widget.id),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await ambilSetoran(); // Retry after refresh
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Terjadi kesalahan';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menerima penjemputan: $errorMsg')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in ambilSetoran: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan koneksi. Coba lagi.')),
        );
      }
    }
  }

  Future<void> batalkanSetoran() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse(
          '${dotenv.env['URL']}/setor-jemput/batal-pengajuan/${widget.id}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PetugasMainWrapper(initialMenu: 1),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await batalkanSetoran(); // Retry after refresh
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Terjadi kesalahan';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membatalkan setoran: $errorMsg')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in batalkanSetoran: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan koneksi. Coba lagi.')),
        );
      }
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
    if (isLoading || pengajuanDetailSetor == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Setor Sampah Jemput")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "Setor Jemput",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              "Baru",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
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
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
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

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(gambarPengguna),
                  ),
                  SizedBox(width: 16),
                  Text(
                    namaPengguna,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6BBE44), Color(0xFF128d54)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Detail Penyetoran :",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tanggal: ${widget.tanggal}",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  Text(
                    "Catatan: ${widget.catatan}",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Estimasi Berat Sampah',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            // Waste Visualization
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.20),
                    blurRadius: 16,
                    offset: Offset(0, 0),
                  ),
                ],
              ),

              child: Column(
                children: [
                  Stack(
                    children: [
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
                          Expanded(child: Text(item['nama'])),
                          Text("${item['berat']}kg"),
                          SizedBox(width: 16),
                          Text("Rp${item['subtotal']}"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Estimasi Insentif',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8), // Estimasi Insentif
            Container(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.20),
                    blurRadius: 16,
                    offset: Offset(0, 0),
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
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                      Text(
                        'Rp $totalHarga',
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Jarak",
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                      Text(
                        _formatDistance(
                          _calculateDistanceInKm(
                            latitudeWarga ?? 0,
                            longitudeWarga ?? 0,
                            latitudeBankSampah ?? 0,
                            longitudeBankSampah ?? 0,
                          ).toDouble(),
                        ),
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Biaya Layanan (Ongkir)",
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                      Text(
                        'Rp $biayaLayanan',
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Perkiraan Insentif',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rp ${totalHarga - biayaLayanan}',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildMapImage(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ), // Kiri dan kanan 16px
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PetugasMapBankSampahMapWargaPage(
                              latitudeWarga: latitudeWarga,
                              longitudeWarga: longitudeWarga,
                              latitudeBankSampah: latitudeBankSampah,
                              longitudeBankSampah: longitudeBankSampah,
                              namaPengguna: namaPengguna,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map),
                  label: Text(
                    "Detail Map",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF128d54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Action Buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 175,
                    child: ElevatedButton(
                      onPressed: batalkanSetoran,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Batalkan Pengambilan",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 145,
                    child: ElevatedButton(
                      onPressed: ambilSetoran,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6BBE44),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Ambil Sampah",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
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
