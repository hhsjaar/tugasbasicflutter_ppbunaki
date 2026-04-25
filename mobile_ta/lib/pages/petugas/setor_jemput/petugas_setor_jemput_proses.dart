import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ta/pages/petugas/detail_map/map_bank_sampah_map_warga_page.dart';
import 'package:mobile_ta/pages/petugas/setor_jemput/petugas_setor_jemput_selesai.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/widget/petugas_main_widget.dart';

class PetugasSetorJemputProses extends StatefulWidget {
  final int id;
  const PetugasSetorJemputProses({required this.id, super.key});

  @override
  State<PetugasSetorJemputProses> createState() =>
      _PetugasSetorJemputProsesState();
}

class _PetugasSetorJemputProsesState extends State<PetugasSetorJemputProses> {
  Map<String, dynamic>? pengajuanDetailSetor;
  Map<String, dynamic>? bankSampah;
  Map<int, Map<String, dynamic>> jenisSampahCache = {};
  List<Map<String, dynamic>> _jenisSampahList = [];
  List<Map<String, dynamic>> _jenisSampahOptions = [];

  List<Map<String, dynamic>> processedSetoran = [];
  int ongkir_per_jarak = 0;
  double totalBerat = 0;
  int totalHarga = 0;
  int biayaLayanan = 0;
  String gambarPengguna = '';
  String namaPengguna = '';
  bool isTotalValid = true;
  String? totalError;

  late double latitudeBankSampah;
  late double longitudeBankSampah;
  late double latitudeWarga;
  late double longitudeWarga;
  late GoogleMapController _mapController;
  late CameraPosition _initialCameraPosition;
  Set<Marker> _markers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await fetchPengajuanDetailSetor();
      await fetchJenisSampahOptions();
      await processInitialData();
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

        _recalculateTotals();
      }
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

  void _recalculateTotals() async {
    totalBerat = 0;
    totalHarga = 0;
    processedSetoran.clear();

    for (var item in _jenisSampahList) {
      final jenisId = item['jenis_sampah_id'] as int?;
      final berat = item['berat'] as double?;

      if (jenisId != null && berat != null) {
        // 1. Cek cache dulu
        if (!jenisSampahCache.containsKey(jenisId)) {
          try {
            // 2. Jika tidak ada di cache, ambil dari API detail
            final authService = AuthService();
            final token = await authService.getToken();

            if (token != null) {
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
                  'nama': data['nama_sampah'] as String,
                  'harga': data['harga_per_satuan'] as int,
                  'warna': data['warna_indikasi'] as String,
                };
              } else if (response.statusCode == 401) {
                final refreshed = await authService.refreshToken();
                if (refreshed) {
                  // Retry the current item
                  if (!jenisSampahCache.containsKey(jenisId)) {
                    final retryResponse = await http.get(
                      Uri.parse('${dotenv.env['URL']}/jenis-sampah/$jenisId'),
                      headers: {
                        'Authorization':
                            'Bearer ${await authService.getToken()}',
                        'Accept': 'application/json',
                      },
                    );
                    if (retryResponse.statusCode == 200) {
                      final retryData = json.decode(retryResponse.body)['data'];
                      jenisSampahCache[jenisId] = {
                        'nama': retryData['nama_sampah'] as String,
                        'harga': retryData['harga_per_satuan'] as int,
                        'warna': retryData['warna_indikasi'] as String,
                      };
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('Gagal mengambil detail jenis sampah: $e');
            // 3. Jika gagal, coba cari di options
            final jenisOption = _jenisSampahOptions.firstWhere(
              (option) => option['id'] == jenisId,
              orElse: () => {},
            );

            if (jenisOption.isNotEmpty) {
              jenisSampahCache[jenisId] = {
                'nama': jenisOption['nama_sampah'] as String,
                'harga': jenisOption['harga_per_satuan'] as int,
                'warna': jenisOption['warna_indikasi'] as String,
              };
            }
          }
        }

        final jenisInfo = jenisSampahCache[jenisId];
        if (jenisInfo != null) {
          final harga = (jenisInfo['harga'] ?? 0) as int;
          final subtotal = (berat * harga).round();

          totalBerat += berat;
          totalHarga += subtotal;

          processedSetoran.add({
            'nama': jenisInfo['nama'] ?? 'Unknown',
            'berat': berat,
            'subtotal': subtotal,
            'warna': jenisInfo['warna'] ?? '#999999',
          });
        }
      }
    }

    calculateServiceFee();
    if (mounted) {
      setState(() {});
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
        final responseData = json.decode(response.body);
        if (responseData['data'] != null && mounted) {
          setState(() {
            pengajuanDetailSetor = responseData['data'];
          });
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await fetchPengajuanDetailSetor();
        }
      } else {
        throw Exception('Gagal memuat data pengajuan');
      }
    } catch (e) {
      debugPrint('Error in fetchPengajuanDetailSetor: $e');
      rethrow;
    }
  }

  Future<void> fetchJenisSampahOptions() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/jenis-sampah'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null && mounted) {
          setState(() {
            _jenisSampahOptions = List<Map<String, dynamic>>.from(
              responseData['data'],
            );
          });
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await fetchJenisSampahOptions();
        }
      }
    } catch (e) {
      debugPrint('Error in fetchJenisSampahOptions: $e');
    }
  }

  Future<void> processInitialData() async {
    if (pengajuanDetailSetor == null) return;
    await fetchJenisSampahOptions();

    final setoranSampah =
        pengajuanDetailSetor!['input_detail']['setoran_sampah'] as List;

    _jenisSampahList =
        setoranSampah.map<Map<String, dynamic>>((item) {
          return {
            'jenis_sampah_id': item['jenis_sampah_id'] as int,
            'berat': (item['berat'] as num).toDouble(),
            'error': null,
          };
        }).toList();

    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      for (var item in setoranSampah) {
        final jenisId = item['jenis_sampah_id'] as int;
        if (!jenisSampahCache.containsKey(jenisId)) {
          try {
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
                'nama': data['nama_sampah'] as String,
                'harga': data['harga_per_satuan'] as int,
                'warna': data['warna_indikasi'] as String,
              };
            } else if (response.statusCode == 401) {
              final refreshed = await authService.refreshToken();
              if (refreshed) {
                // Retry for this item
                final retryResponse = await http.get(
                  Uri.parse('${dotenv.env['URL']}/jenis-sampah/$jenisId'),
                  headers: {
                    'Authorization': 'Bearer ${await authService.getToken()}',
                    'Accept': 'application/json',
                  },
                );
                if (retryResponse.statusCode == 200) {
                  final retryData = json.decode(retryResponse.body)['data'];
                  jenisSampahCache[jenisId] = {
                    'nama': retryData['nama_sampah'] as String,
                    'harga': retryData['harga_per_satuan'] as int,
                    'warna': retryData['warna_indikasi'] as String,
                  };
                }
              }
            }
          } catch (e) {
            debugPrint('Gagal mengambil detail jenis sampah: $e');
            // Fallback ke options jika gagal
            final jenisOption = _jenisSampahOptions.firstWhere(
              (option) => option['id'] == jenisId,
              orElse: () => {},
            );

            if (jenisOption.isNotEmpty) {
              jenisSampahCache[jenisId] = {
                'nama': jenisOption['nama_sampah'] as String,
                'harga': jenisOption['harga_per_satuan'] as int,
                'warna': jenisOption['warna_indikasi'] as String,
              };
            }
          }
        }
      }
    }

    _recalculateTotals();
  }

  void _removeJenisSampah(int index) {
    if (_jenisSampahList.length > 1) {
      setState(() {
        _jenisSampahList.removeAt(index);
        _recalculateTotals();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimal harus ada 1 jenis sampah')),
      );
    }
  }

  Future<void> konfirmasiSetoran() async {
    // Validasi input
    bool hasError = false;
    for (var i = 0; i < _jenisSampahList.length; i++) {
      final item = _jenisSampahList[i];
      if (item['jenis_sampah_id'] == null) {
        if (mounted) {
          setState(() {
            _jenisSampahList[i]['error'] = 'Pilih jenis sampah';
          });
        }
        hasError = true;
      }
      if (item['berat'] == null || item['berat'] <= 0) {
        if (mounted) {
          setState(() {
            _jenisSampahList[i]['error'] = 'Berat harus lebih dari 0';
          });
        }
        hasError = true;
      }
    }

    if (hasError) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Harap periksa input Anda')));
      }
      return;
    }

    if (mounted) {
      setState(() => isLoading = true);
    }

    final authService = AuthService();
    final token = await authService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }

    try {
      // Pastikan perhitungan terbaru
      _recalculateTotals();

      final setoranSampah = await Future.wait(
        _jenisSampahList.map((item) async {
          final jenisId = item['jenis_sampah_id'] as int;
          int harga = 0;

          // Cek cache terlebih dahulu
          if (jenisSampahCache.containsKey(jenisId)) {
            harga = jenisSampahCache[jenisId]?['harga'] ?? 0;
          } else {
            // Jika tidak ada di cache, ambil dari API
            try {
              final response = await http.get(
                Uri.parse('${dotenv.env['URL']}/jenis-sampah/$jenisId'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Accept': 'application/json',
                },
              );

              if (response.statusCode == 200) {
                final data = json.decode(response.body)['data'];
                harga = data['harga_per_satuan'] as int;
                jenisSampahCache[jenisId] = {
                  'nama': data['nama_sampah'],
                  'harga': harga,
                  'warna': data['warna_indikasi'],
                };
              } else if (response.statusCode == 401) {
                final refreshed = await authService.refreshToken();
                if (refreshed) {
                  final retryResponse = await http.get(
                    Uri.parse('${dotenv.env['URL']}/jenis-sampah/$jenisId'),
                    headers: {
                      'Authorization': 'Bearer ${await authService.getToken()}',
                      'Accept': 'application/json',
                    },
                  );
                  if (retryResponse.statusCode == 200) {
                    final retryData = json.decode(retryResponse.body)['data'];
                    harga = retryData['harga_per_satuan'] as int;
                    jenisSampahCache[jenisId] = {
                      'nama': retryData['nama_sampah'],
                      'harga': harga,
                      'warna': retryData['warna_indikasi'],
                    };
                  }
                }
              }
            } catch (e) {
              debugPrint('Gagal mengambil harga jenis sampah: $e');
              // Fallback ke options jika gagal
              final jenisOption = _jenisSampahOptions.firstWhere(
                (option) => option['id'] == jenisId,
                orElse: () => {},
              );
              if (jenisOption.isNotEmpty) {
                harga = jenisOption['harga_per_satuan'] as int;
              }
            }
          }

          return {
            'jenis_sampah_id': jenisId,
            'berat': item['berat'] as double,
            'harga': harga, // Tambahkan harga ke data yang dikirim
          };
        }),
      );

      final totalAkhir = totalHarga - biayaLayanan;

      if (totalAkhir <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Total harga tidak boleh kurang dari biaya layanan',
              ),
            ),
          );
          setState(() => isLoading = false);
        }
        return;
      }

      final response = await http.patch(
        Uri.parse('${dotenv.env['URL']}/setor-jemput/konfirmasi/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'setoran_sampah': setoranSampah,
          'koordinat_warga': '$latitudeWarga,$longitudeWarga',
          'total_berat': totalBerat,
          'total_harga': totalAkhir,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PetugasSetorJemputSelesai(id: widget.id),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await konfirmasiSetoran(); // Retry after refresh
        } else {
          throw Exception('Gagal mengkonfirmasi setoran: Session expired');
        }
      } else {
        throw Exception('Gagal mengkonfirmasi setoran: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // perhitungan jarak
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

    final estimatedTotal = totalHarga - biayaLayanan;
    isTotalValid = estimatedTotal >= 0;
    totalError = isTotalValid ? null : "Total tidak boleh negatif";

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
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              "Proses",
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // User Profile
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(gambarPengguna),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      namaPengguna,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // In your build method, add this:
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lokasi",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      label: Text("Detail Map", style: GoogleFonts.poppins()),
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
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Estimasi Berat Sampah",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 8),
            // Waste Visualization
            Container(
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
              child: Column(
                children: [
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
                              final proportion =
                                  totalBerat > 0
                                      ? (item['berat'] ?? 0) / totalBerat
                                      : 0;
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
                  SizedBox(height: 12),
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
                            "${item['berat']?.toStringAsFixed(2)}kg",
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

            SizedBox(height: 16),
            Text(
              "Estimasi Harga Sampah",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 8),
            // Estimasi Insentif
            Container(
              padding: EdgeInsets.all(16),
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
                  SizedBox(height: 4),
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
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Perkiraan Insentif',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rp ${estimatedTotal >= 0 ? estimatedTotal : 0}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: isTotalValid ? Colors.black : Colors.red,
                            ),
                          ),
                          if (!isTotalValid)
                            Text(
                              totalError!,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            Text(
              "Masukkan Berat Sampah",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 8),
            // Editable Waste List
            Container(
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
              child: Column(
                children: [
                  ..._jenisSampahList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              value: item['jenis_sampah_id'],
                              hint: Text(
                                'Pilih jenis',
                                style: GoogleFonts.poppins(), // Added Poppins
                              ),
                              items:
                                  _jenisSampahOptions.map((option) {
                                    return DropdownMenuItem<int?>(
                                      value: option['id'] as int?,
                                      child: Text(
                                        option['nama_sampah'],
                                        style:
                                            GoogleFonts.poppins(), // Added Poppins
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _jenisSampahList[index]['jenis_sampah_id'] =
                                      value;
                                  _recalculateTotals();
                                });
                              },
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 14,
                              ), // Added for dropdown text
                              dropdownColor:
                                  Colors.white, // Optional: better readability
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  initialValue: item['berat']?.toString(),
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Berat (kg)',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                    ), // Added Poppins
                                    // errorText: item['error'], // Hapus errorText di sini
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                  ), // Added for input text
                                  onChanged: (value) {
                                    if (value.isEmpty) {
                                      setState(() {
                                        _jenisSampahList[index]['berat'] = null;
                                        _jenisSampahList[index]['error'] = null;
                                        _recalculateTotals();
                                      });
                                      return;
                                    }

                                    final parsed = double.tryParse(value);
                                    String? error;

                                    if (parsed == null) {
                                      error = 'Harus berupa angka';
                                    } else if (parsed < 0.5) {
                                      error = 'Minimum 0.5 kg';
                                    } else if (parsed > 50) {
                                      error = 'Maksimum 50 kg';
                                    } else if (!RegExp(
                                      r'^\d+(\.\d{1,2})?$',
                                    ).hasMatch(value)) {
                                      error = 'Maksimal 2 angka desimal';
                                    }

                                    setState(() {
                                      if (error != null) {
                                        _jenisSampahList[index]['berat'] = null;
                                        _jenisSampahList[index]['error'] =
                                            error;
                                      } else {
                                        _jenisSampahList[index]['berat'] =
                                            parsed;
                                        _jenisSampahList[index]['error'] = null;
                                      }
                                      _recalculateTotals();
                                    });
                                  },
                                ),
                                if (item['error'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item['error'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.red[700],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeJenisSampah(index),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _jenisSampahList.add({
                          'jenis_sampah_id': null,
                          'berat': null,
                          'error': null,
                        });
                        _recalculateTotals();
                      });
                    },
                    icon: Icon(Icons.add, color: Colors.green),
                    label: Text(
                      'Tambah Jenis Sampah',
                      style: GoogleFonts.poppins(
                        // Added Poppins
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Confirmation Button
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed:
                    (isLoading || !isTotalValid) ? null : konfirmasiSetoran,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF128d54),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child:
                    isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          "Konfirmasi Setoran",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseHexColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll("#", "");
      if (hexColor.length == 6) hexColor = "FF$hexColor";
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
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
