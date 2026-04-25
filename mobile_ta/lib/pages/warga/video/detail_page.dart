import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:google_fonts/google_fonts.dart';

class WargaDetailVideoPage extends StatefulWidget {
  final int videoId;

  const WargaDetailVideoPage({super.key, required this.videoId});

  @override
  State<WargaDetailVideoPage> createState() => _WargaDetailVideoPageState();
}

class _WargaDetailVideoPageState extends State<WargaDetailVideoPage> {
  late final Player _player;
  late final VideoController _controller;
  bool _isLoading = true;
  bool _videoReady = false;
  bool _hasError = false;

  String _judul = '';
  String _deskripsi = '';
  String _tanggal = '';
  String _videoUrl = '';

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    fetchVideoDetail();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> fetchVideoDetail() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['URL']}/video/${widget.videoId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];

        _judul = data['judul_video'];
        _deskripsi = data['deskripsi_video'];
        _tanggal = DateFormat(
          'd MMMM yyyy',
          'id_ID',
        ).format(DateTime.parse(data['created_at']));
        _videoUrl = data['video_url'];

        if (_videoUrl.isEmpty || !_videoUrl.startsWith('http')) {
          throw Exception("Invalid video URL: $_videoUrl");
        }

        await _player.open(Media(_videoUrl));
        await _player.pause(); // 🔴 Agar tidak autoplay

        setState(() {
          _isLoading = false;
          _videoReady = true;
        });
      } else {
        throw Exception('Gagal memuat detail video');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF128d54),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edukasi Video',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 10),
                    Text('Gagal memuat video.'),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child:
                          _videoReady
                              ? Video(controller: _controller)
                              : const Center(
                                child: CircularProgressIndicator(),
                              ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _judul,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF128d54),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _tanggal,
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _deskripsi,
                      style: GoogleFonts.poppins(fontSize: 16, height: 1.6),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
    );
  }
}
