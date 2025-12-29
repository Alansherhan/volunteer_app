import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class Map_Screen extends StatefulWidget {
  const Map_Screen({super.key});

  @override
  State<Map_Screen> createState() => _Map_ScreenState();
}

class _Map_ScreenState extends State<Map_Screen> {
  GoogleMapController? mapController;

  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // --- CRITICAL FIX: Dispose the controller to prevent leaks ---
  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("DEBUG: Location services are disabled.");

      // FIX: Check if mounted before setState
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please turn on GPS.'),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      print("DEBUG: Fetching current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // FIX: Check if mounted before updating position and UI
      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentPosition, zoom: 15),
          ),
        );
      }
    } catch (e) {
      print("DEBUG: Error getting location: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        // appBar: AppBar(title: const Text('Live User Location')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 14.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                  // Animate to position if it was found while map was loading
                  if (_currentPosition.latitude != 37.7749) {
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: _currentPosition, zoom: 15),
                      ),
                    );
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
      ),
    );
  }
}
