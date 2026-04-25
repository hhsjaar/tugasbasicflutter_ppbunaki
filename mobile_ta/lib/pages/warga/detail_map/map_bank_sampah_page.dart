import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class WargaMapBankSampahPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String namaBank;

  const WargaMapBankSampahPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.namaBank,
  });

  @override
  State<WargaMapBankSampahPage> createState() => _WargaMapBankSampahPageState();
}

class _WargaMapBankSampahPageState extends State<WargaMapBankSampahPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createCustomMarker();
  }

  Future<BitmapDescriptor> _createBankMarkerWithLabel() async {
    try {
      const double markerSize = 150.0; // Larger size for better text visibility
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw marker background (green circle)
      final Paint paint =
          Paint()
            ..color = const Color(0xFF128d54)
            ..style = PaintingStyle.fill;

      // Draw shadow first
      canvas.drawCircle(
        Offset(markerSize / 2, markerSize / 2),
        markerSize / 2 - 5,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Then draw main circle
      canvas.drawCircle(
        Offset(markerSize / 2, markerSize / 2),
        markerSize / 2 - 5,
        paint,
      );

      // Configure text style
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: "Bank Sampah",
          style: GoogleFonts.poppins(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      // Layout and draw the text
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          markerSize / 2 - textPainter.width / 2,
          markerSize / 2 - textPainter.height / 2,
        ),
      );

      // Convert to image
      final ui.Image image = await recorder.endRecording().toImage(
        markerSize.toInt(),
        markerSize.toInt(),
      );
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      // Fallback to default green marker if custom fails
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<void> _createCustomMarker() async {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('bank_sampah'),
          position: LatLng(widget.latitude, widget.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: widget.namaBank),
        ),
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 15,
    );

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
          'Detail Map',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF128d54),
            fontSize: 22,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                initialCameraPosition: initialCameraPosition,
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Show InfoWindow automatically
                  Future.delayed(Duration(milliseconds: 500), () {
                    _mapController.showMarkerInfoWindow(
                      const MarkerId('bank_sampah'),
                    );
                  });
                },

                zoomControlsEnabled: false,
                myLocationEnabled: false,
              ),
    );
  }
}
