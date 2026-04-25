import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/widget/petugas_main_widget.dart';
import 'package:path/path.dart' as Path;
import 'package:google_fonts/google_fonts.dart';

class PetugasEditProfilPage extends StatefulWidget {
  final Map<String, dynamic>? profilData;
  const PetugasEditProfilPage({super.key, this.profilData});

  @override
  State<PetugasEditProfilPage> createState() => _PetugasEditProfilPageState();
}

class _PetugasEditProfilPageState extends State<PetugasEditProfilPage> {
  late TextEditingController _namaController;
  late TextEditingController _telponController;
  late TextEditingController _alamatController;
  late TextEditingController _koordinatController;
  GoogleMapController? _mapController;
  late CameraPosition _initialCameraPosition;
  Set<Marker> _markers = {};
  LatLng? _currentLatLng;
  File? _profileImage;
  bool _isLoading = false;
  bool _isMapLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.profilData?['nama_pengguna'] ?? '',
    );
    _telponController = TextEditingController(
      text: widget.profilData?['no_hp_pengguna'] ?? '',
    );
    _alamatController = TextEditingController(
      text: widget.profilData?['alamat_pengguna'] ?? '',
    );
    _koordinatController = TextEditingController(
      text: widget.profilData?['koordinat_pengguna'] ?? '',
    );

    _initializeMap();
  }

  void _initializeMap() {
    final initialCoords =
        widget.profilData?['koordinat_pengguna'] ?? '-6.2088,106.8456';
    _currentLatLng = _parseCoordinates(initialCoords);

    _initialCameraPosition = CameraPosition(target: _currentLatLng!, zoom: 15);

    _updateMarkers();
  }

  LatLng _parseCoordinates(String koordinat) {
    try {
      final cleanedKoordinat = koordinat.trim().replaceAll(' ', '');
      final parts = cleanedKoordinat.split(',');

      if (parts.length != 2) {
        throw FormatException('Format koordinat tidak valid');
      }

      double latitude = double.tryParse(parts[0]) ?? -6.2088;
      double longitude = double.tryParse(parts[1]) ?? 106.8456;

      return LatLng(latitude, longitude);
    } catch (e) {
      debugPrint('Error parsing coordinates: $e');
      return const LatLng(-6.2088, 106.8456); // Default Jakarta coordinates
    }
  }

  void _updateMarkers() {
    if (_currentLatLng == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentLatLng!,
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLatLng!));
  }

  void _handleKoordinatChanged() {
    try {
      final newLatLng = _parseCoordinates(_koordinatController.text);
      setState(() {
        _currentLatLng = newLatLng;
        _updateMarkers();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Format koordinat tidak valid: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pilih Foto Profil",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo, size: 40),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      const Text("Galeri"),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 40),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      const Text("Kamera"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isMapLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Lokasi/GPS tidak aktif. Mohon aktifkan terlebih dahulu.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin lokasi ditolak. Tidak dapat melanjutkan.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak permanen. Mohon aktifkan manual di pengaturan aplikasi.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentLatLng = newLatLng;
          _koordinatController.text =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isLoading = false;
          _isMapLoading = false;
        });
      }

      _updateMarkers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _isMapLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (mounted) setState(() => _isLoading = true);

    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Token tidak ditemukan')));
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      var uri = Uri.parse('${dotenv.env['URL']}/profil');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['nama_pengguna'] = _namaController.text;
      request.fields['alamat_pengguna'] = _alamatController.text;
      request.fields['no_hp_pengguna'] = _telponController.text;
      request.fields['koordinat_pengguna'] = _koordinatController.text;
      request.fields['_method'] = 'PUT';

      if (_profileImage != null) {
        var stream = http.ByteStream(_profileImage!.openRead());
        var length = await _profileImage!.length();
        var multipartFile = http.MultipartFile(
          'gambar_pengguna',
          stream,
          length,
          filename: Path.basename(_profileImage!.path),
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diedit'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PetugasMainWrapper()),
            (Route<dynamic> route) => false,
          );
        }
      } else if (response.statusCode == 401) {
        final refreshed = await authService.refreshToken();
        if (refreshed) {
          await _submitForm();
        }
      } else {
        final resData = await response.stream.bytesToString();
        final json = jsonDecode(resData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(json['message'] ?? 'Gagal edit profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Edit Profil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF128d54)),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : NetworkImage(
                                        (widget.profilData?['gambar_pengguna'] ??
                                                    '')
                                                .isNotEmpty
                                            ? widget.profilData!['gambar_url']
                                            : 'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg',
                                      )
                                      as ImageProvider,
                        ),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form Data
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6BBE44), Color(0xFF128d54)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
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
                      _buildTextField("Nama Lengkap", _namaController),
                      _buildTextField("Telpon", _telponController),
                      _buildTextField("Alamat", _alamatController),
                      _buildCoordinateField(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.location_on, size: 20),
                          label: const Text('Lokasi Terkini'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF128d54),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _getCurrentLocation,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildMapWidget(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isMapLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF128d54)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCoordinateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Titik Koordinat",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _koordinatController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map),
              onPressed: _handleKoordinatChanged,
            ),
          ),
          onChanged: (value) => _handleKoordinatChanged(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMapWidget() {
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: (LatLng position) {
            setState(() {
              _currentLatLng = position;
              _koordinatController.text =
                  '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
              _updateMarkers();
            });
          },
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _telponController.dispose();
    _alamatController.dispose();
    _koordinatController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
