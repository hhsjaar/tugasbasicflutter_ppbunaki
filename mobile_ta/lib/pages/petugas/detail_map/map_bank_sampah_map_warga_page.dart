import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PetugasMapBankSampahMapWargaPage extends StatefulWidget {
  final double latitudeWarga;
  final double longitudeWarga;
  final double latitudeBankSampah;
  final double longitudeBankSampah;
  final String namaPengguna;

  const PetugasMapBankSampahMapWargaPage({
    required this.latitudeWarga,
    required this.longitudeWarga,
    required this.latitudeBankSampah,
    required this.longitudeBankSampah,
    required this.namaPengguna,
    super.key,
  });

  @override
  State<PetugasMapBankSampahMapWargaPage> createState() =>
      _PetugasMapBankSampahMapWargaPageState();
}

class _PetugasMapBankSampahMapWargaPageState
    extends State<PetugasMapBankSampahMapWargaPage> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  Future<void> _initializeMarkers() async {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('warga'),
          position: LatLng(widget.latitudeWarga, widget.longitudeWarga),
          infoWindow: const InfoWindow(title: "Lokasi Warga"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: const MarkerId('bank_sampah'),
          position: LatLng(
            widget.latitudeBankSampah,
            widget.longitudeBankSampah,
          ),
          infoWindow: const InfoWindow(title: "Lokasi Bank Sampah"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
      _isLoading = false;
    });
  }

  LatLngBounds _getBounds() {
    final latitudes = [widget.latitudeWarga, widget.latitudeBankSampah];
    final longitudes = [widget.longitudeWarga, widget.longitudeBankSampah];

    final northeast = LatLng(latitudes.reduce(max), longitudes.reduce(max));
    final southwest = LatLng(latitudes.reduce(min), longitudes.reduce(min));

    return LatLngBounds(northeast: northeast, southwest: southwest);
  }

  @override
  Widget build(BuildContext context) {
    final midLat = (widget.latitudeWarga + widget.latitudeBankSampah) / 2;
    final midLng = (widget.longitudeWarga + widget.longitudeBankSampah) / 2;

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
                initialCameraPosition: CameraPosition(
                  target: LatLng(midLat, midLng),
                  zoom: 12,
                ),
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngBounds(_getBounds(), 100),
                    );
                  });
                },
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
    );
  }
}
