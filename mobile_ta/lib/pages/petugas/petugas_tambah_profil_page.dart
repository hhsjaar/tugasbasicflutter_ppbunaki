import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_ta/services/auth_service.dart';
import 'package:mobile_ta/widget/petugas_main_widget.dart';
import 'package:path/path.dart' as Path;

class PetugasTambahProfilPage extends StatefulWidget {
  const PetugasTambahProfilPage({super.key});

  @override
  State<PetugasTambahProfilPage> createState() =>
      _PetugasTambahProfilPageState();
}

class _PetugasTambahProfilPageState extends State<PetugasTambahProfilPage> {
  final TextEditingController _namapenggunaController = TextEditingController();
  final TextEditingController _alamatpenggunaController =
      TextEditingController();
  final TextEditingController _nohppenggunaController = TextEditingController();
  final TextEditingController _koordinatpenggunaController =
      TextEditingController();

  File? _profileImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 75);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                "Pilih Foto Profil",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Dari Galeri"),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Dari Kamera"),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
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

      request.fields['nama_pengguna'] = _namapenggunaController.text;
      request.fields['alamat_pengguna'] = _alamatpenggunaController.text;
      request.fields['no_hp_pengguna'] = _nohppenggunaController.text;
      request.fields['koordinat_pengguna'] = _koordinatpenggunaController.text;

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
              content: Text('Profil berhasil ditambahkan'),
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
              content: Text(json['message'] ?? 'Gagal menambahkan profil'),
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi tidak aktif. Mohon aktifkan lokasi.'),
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
                content: Text('Izin lokasi ditolak'),
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

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _koordinatpenggunaController.text =
            '${position.latitude}, ${position.longitude}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:
          () async => false, 
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            'Tambah Profil',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Color(0xFF128d54),
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF128d54)),
              onPressed: _isLoading ? null : _submitForm,
            ),
          ],
        ),
        body: SingleChildScrollView(
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
                                : const NetworkImage(
                                      'https://i.pinimg.com/736x/8a/e9/e9/8ae9e92fa4e69967aa61bf2bda967b7b.jpg',
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
                    _buildTextField("Nama Lengkap", _namapenggunaController),
                    _buildTextField("Telpon", _nohppenggunaController),
                    _buildTextField("Alamat", _alamatpenggunaController),
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
            ],
          ),
        ),
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
          controller: _koordinatpenggunaController,
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

  @override
  void dispose() {
    _namapenggunaController.dispose();
    _nohppenggunaController.dispose();
    _alamatpenggunaController.dispose();
    _koordinatpenggunaController.dispose();
    super.dispose();
  }
}
