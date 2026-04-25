import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/pages/warga/setor_jemput/status_page.dart';
import 'package:google_fonts/google_fonts.dart';

class WargaKonfirmasiSetorJemputPage extends StatefulWidget {
  final List<Map<String, dynamic>> dataSetoran;
  final String tanggal;
  final String? catatan;
  final Map<String, dynamic>? profilData;

  const WargaKonfirmasiSetorJemputPage({
    super.key,
    this.profilData,
    required this.dataSetoran,
    required this.tanggal,
    required this.catatan,
  });

  @override
  State<WargaKonfirmasiSetorJemputPage> createState() =>
      _WargaKonfirmasiSetorJemputPageState();
}

class _WargaKonfirmasiSetorJemputPageState
    extends State<WargaKonfirmasiSetorJemputPage> {
  Map<String, dynamic>? bankSampah;
  String namaBank = 'Memuat...';
  String deskripsiBank = 'Memuat...';
  String alamatBank = 'Memuat...';
  String namaAdmin = 'Memuat...';
  String emailAdmin = 'Memuat...';
  String noHpAdmin = 'Memuat...';
  int ongkir_per_jarak = 0;

  double? latitudeBankSampah;
  double? longitudeBankSampah;
  double? latitudeWarga;
  double? longitudeWarga;
  GoogleMapController? _mapController;
  CameraPosition? _initialCameraPosition;
  Set<Marker> _markers = {};

  final Map<int, Map<String, dynamic>> jenisSampahCache = {};
  List<Map<String, dynamic>> processedSetoran = [];
  double totalBerat = 0.0;
  int totalHarga = 0;
  int biayaLayanan = 0;
  bool isLoading = true;
  String? formattedDate;
  bool isTotalValid = true;
  String? totalError;
  bool isJarakDalamLayanan = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final inputDate = DateFormat('dd/MM/yyyy').parse(widget.tanggal);
      formattedDate = DateFormat('yyyy-MM-dd').format(inputDate);
    } catch (e) {
      formattedDate = null;
    }

    try {
      await fetchBankSampah();
      await processSetoran();
      if (bankSampah != null) {
        namaBank = bankSampah?['nama_bank_sampah'] ?? 'Tidak tersedia';
        latitudeBankSampah = double.tryParse(bankSampah?['latitude'] ?? '');
        longitudeBankSampah = double.tryParse(bankSampah?['longitude'] ?? '');

        latitudeWarga = double.tryParse(widget.profilData?['latitude'] ?? '');
        longitudeWarga = double.tryParse(widget.profilData?['longitude'] ?? '');

        deskripsiBank =
            bankSampah?['deskripsi_bank_sampah'] ?? 'Tidak tersedia';
        alamatBank = bankSampah?['alamat_bank_sampah'] ?? 'Tidak tersedia';
        namaAdmin =
            bankSampah?['user']?['profil']?['nama_pengguna'] ??
            'Tidak tersedia';
        emailAdmin = bankSampah?['user']?['email'] ?? 'Tidak tersedia';
        noHpAdmin =
            bankSampah?['user']?['profil']?['no_hp_pengguna'] ??
            'Tidak tersedia';

        ongkir_per_jarak = bankSampah?['ongkir_per_jarak'] ?? 0;
      }
      if (latitudeBankSampah != null &&
          longitudeBankSampah != null &&
          latitudeWarga != null &&
          longitudeWarga != null) {
        final midLat = (latitudeBankSampah! + latitudeWarga!) / 2;
        final midLng = (longitudeBankSampah! + longitudeWarga!) / 2;

        _initialCameraPosition = CameraPosition(
          target: LatLng(midLat, midLng),
          zoom: 12,
        );
      }

      calculateServiceFee();

      final totalAkhir = totalHarga - biayaLayanan;
      isTotalValid = totalAkhir >= 0;
      totalError = isTotalValid ? null : "Total insentif tidak boleh negatif";

      _updateMarkers();
    } catch (e) {
      debugPrint('Error in fetchData: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _updateMarkers() {
    if (latitudeBankSampah == null ||
        longitudeBankSampah == null ||
        latitudeWarga == null ||
        longitudeWarga == null)
      return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('bank_sampah_location'),
          position: LatLng(latitudeBankSampah!, longitudeBankSampah!),
          infoWindow: InfoWindow(title: namaBank),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: const MarkerId('warga_location'),
          position: LatLng(latitudeWarga!, longitudeWarga!),
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };

      // Fit camera to show both markers
      if (_mapController != null) {
        final bounds = _getBounds();
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      }
    });
  }

  LatLngBounds _getBounds() {
    final northeast = LatLng(
      max(latitudeBankSampah!, latitudeWarga!),
      max(longitudeBankSampah!, longitudeWarga!),
    );
    final southwest = LatLng(
      min(latitudeBankSampah!, latitudeWarga!),
      min(longitudeBankSampah!, longitudeWarga!),
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

  Future<void> processSetoran() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      if (mounted) setState(() => isLoading = false);
      return;
    }

    // Reset values
    processedSetoran.clear();
    totalBerat = 0;
    totalHarga = 0;

    try {
      for (var item in widget.dataSetoran) {
        final int jenisId = item['jenis_sampah_id'];
        final double berat = item['berat'] * 1.0;

        Map<String, dynamic> jenisData;
        if (jenisSampahCache.containsKey(jenisId)) {
          jenisData = jenisSampahCache[jenisId]!;
        } else {
          final response = await http.get(
            Uri.parse('${dotenv.env['URL']}/jenis-sampah/$jenisId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body)['data'];
            jenisData = {
              'nama': data['nama_sampah'],
              'harga': data['harga_per_satuan'],
              'warna': data['warna_indikasi'],
            };
            jenisSampahCache[jenisId] = jenisData;
          } else if (response.statusCode == 401) {
            final refreshed = await authService.refreshToken();
            if (refreshed) {
              return await processSetoran(); // Retry entire process
            }
            break; // Skip if refresh fails
          } else {
            debugPrint('Gagal ambil data jenis sampah id: $jenisId');
            continue;
          }
        }

        final int harga = jenisData['harga'];
        final int subtotal = (berat * harga).round();

        processedSetoran.add({
          'nama': jenisData['nama'],
          'berat': berat,
          'harga': harga,
          'subtotal': subtotal,
          'warna': jenisData['warna'],
        });

        totalBerat += berat;
        totalHarga += subtotal;
      }
    } catch (e) {
      debugPrint('Error in processSetoran: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> storePengajuanSetorJemput() async {
    final authService = AuthService();
    final token = await authService.getToken();

    // Validasi awal
    calculateServiceFee();
    final totalAkhir = totalHarga - biayaLayanan;

    if (totalAkhir < 0) {
      if (mounted) {
        setState(() {
          isTotalValid = false;
          totalError = "Total insentif tidak boleh negatif";
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(totalError!)));
      }
      return;
    }

    if (formattedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tanggal tidak valid.')));
      }
      return;
    }

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token tidak ditemukan. Silakan login ulang.'),
          ),
        );
      }
      return;
    }

    try {
      if (mounted) setState(() => isLoading = true);

      final setoranSampah =
          widget.dataSetoran.map((item) {
            return {
              "jenis_sampah_id": item['jenis_sampah_id'],
              "berat": item['berat'],
            };
          }).toList();

      final response = await http.post(
        Uri.parse("${dotenv.env['URL']}/setor-jemput"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'waktu_pengajuan': formattedDate,
          'catatan_petugas': widget.catatan ?? '',
          'setoran_sampah': setoranSampah,
          'total_berat': totalBerat,
          'total_harga': totalAkhir,
        }),
      );

      if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await storePengajuanSetorJemput();
          return;
        }
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Berhasil mengirim'),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const WargaStatusTungguSetorJemput(),
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Gagal mengirim'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error in storePengajuanSetorJemput: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan, coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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
    if (latitudeWarga == null ||
        longitudeWarga == null ||
        latitudeBankSampah == null ||
        longitudeBankSampah == null) {
      biayaLayanan = 0;
      isJarakDalamLayanan = true; // default dianggap aman
      return;
    }

    final jarak = _calculateDistanceInKm(
      latitudeWarga!,
      longitudeWarga!,
      latitudeBankSampah!,
      longitudeBankSampah!,
    );

    // Set status jarak aman atau tidak
    isJarakDalamLayanan = jarak <= 10;

    biayaLayanan = jarak * ongkir_per_jarak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Setor Jemput',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Komposisi Sampah
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Komposisi Sampah",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF128d54),
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                              item['berat'] / totalBerat;
                                          return Expanded(
                                            flex: (proportion * 1000).round(),
                                            child: Container(
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Color(
                                                  int.parse(
                                                    item['warna']
                                                        .toString()
                                                        .replaceAll(
                                                          '#',
                                                          '0xff',
                                                        ),
                                                  ),
                                                ),
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
                              ...processedSetoran.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.square,
                                        color: Color(
                                          int.parse(
                                            item['warna'].toString().replaceAll(
                                              '#',
                                              '0xff',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Estimasi Insentif
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Estimasi Insentif",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF128d54),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Total harga sampah selalu ditampilkan
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Sampah",
                                    style: GoogleFonts.poppins(),
                                  ),
                                  Text(
                                    'Rp$totalHarga',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ],
                              ),
                              const Divider(),

                              // Jarak selalu ditampilkan
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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

                              // Jika jarak dalam layanan → tampilkan ongkir + total
                              if (isJarakDalamLayanan) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Biaya Layanan (Ongkir)",
                                      style: GoogleFonts.poppins(),
                                    ),
                                    Text(
                                      'Rp $biayaLayanan',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total Insentif",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Rp${totalHarga - biayaLayanan}',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isTotalValid
                                                    ? Colors.black
                                                    : Colors.red,
                                          ),
                                        ),
                                        if (!isTotalValid)
                                          Text(
                                            totalError!,
                                            style: GoogleFonts.poppins(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Jika jarak di luar layanan → tampilkan warning card
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Jarak yang dilayani kurang dari 10 KM",
                                          style: GoogleFonts.poppins(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Detail Penyetoran
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 8,
                                offset: Offset(0, 2),
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
                                "Catatan: ${widget.catatan ?? "-"}",
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                        ),
                        // Informasi Bank Sampah
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 8,
                                offset: Offset(0, 2),
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
                              Text(
                                "Deskripsi: $deskripsiBank",
                                style: GoogleFonts.poppins(),
                              ),
                              Text(
                                "Alamat: $alamatBank",
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        // Map
                        _buildMapImage(),
                        const SizedBox(height: 20),
                        // Kontak Admin
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 8,
                                offset: Offset(0, 2),
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF128d54),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                (isLoading ||
                                        !isTotalValid ||
                                        !isJarakDalamLayanan)
                                    ? null
                                    : storePengajuanSetorJemput,

                            child:
                                isLoading
                                    ? const CircularProgressIndicator()
                                    : Text(
                                      'Konfirmasi Setoran',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMapImage() {
    if (latitudeBankSampah == null ||
        longitudeBankSampah == null ||
        latitudeWarga == null ||
        longitudeWarga == null ||
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
            // After map is created, fit the bounds
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(_getBounds(), 50.0),
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
