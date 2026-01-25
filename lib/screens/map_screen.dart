import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/services/navigation_service.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class Map_Screen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? markerTitle;
  final bool showNavigation; // Enable navigation mode with route display

  const Map_Screen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.markerTitle,
    this.showNavigation = false,
  });

  @override
  State<Map_Screen> createState() => _Map_ScreenState();
}

class _Map_ScreenState extends State<Map_Screen> {
  GoogleMapController? mapController;

  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  bool _isLoading = true;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounceTimer;

  // Selected location marker
  Set<Marker> _markers = {};
  LatLng? _selectedLocation;

  // Navigation/Route state
  Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _directionSteps = [];
  String _routeDistance = '';
  String _routeDuration = '';
  bool _isLoadingRoute = false;
  LatLng? _userLocation;

  // Relief centers state
  Set<Marker> _reliefCenterMarkers = {};
  bool _showReliefCenters = true;

  /// Check if we have initial coordinates to show
  bool get _hasInitialCoordinates =>
      widget.initialLatitude != null && widget.initialLongitude != null;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchReliefCenters();

    if (_hasInitialCoordinates) {
      // If we have initial coordinates, use them
      _initializeWithCoordinates();
    } else {
      // Otherwise get user's location
      _getUserLocation();
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeWithCoordinates() async {
    final destLat = widget.initialLatitude!;
    final destLng = widget.initialLongitude!;
    final destination = LatLng(destLat, destLng);

    // Get user's current location first
    LatLng? userPos;
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userPos = LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Use a default if we can't get location
      userPos = null;
    }

    if (!mounted) return;

    setState(() {
      _selectedLocation = destination;
      _userLocation = userPos;

      // Set markers
      _markers = {
        // Destination marker (red)
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          infoWindow: InfoWindow(title: widget.markerTitle ?? 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };

      // Add origin marker if we have user location
      if (userPos != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: userPos,
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }

      _currentPosition = userPos ?? destination;
      _isLoading = false;
    });

    // Fetch route if navigation mode and we have user location
    if (widget.showNavigation && userPos != null) {
      _fetchRoute(userPos, destination);
    }
  }

  Future<void> _fetchRoute(LatLng origin, LatLng destination) async {
    setState(() => _isLoadingRoute = true);

    final routeData = await NavigationService.getRoute(
      origin: origin,
      destination: destination,
    );

    if (!mounted) return;

    if (routeData != null) {
      final polylinePoints = routeData['polylinePoints'] as List<LatLng>;

      setState(() {
        _routeDistance = routeData['distance'];
        _routeDuration = routeData['duration'];
        _directionSteps = List<Map<String, dynamic>>.from(routeData['steps']);
        _isLoadingRoute = false;

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: AppTheme.primaryColor,
            width: 5,
          ),
        };
      });

      // Fit map to show entire route
      _fitMapToRoute(origin, destination);
    } else {
      setState(() => _isLoadingRoute = false);
    }
  }

  void _fitMapToRoute(LatLng origin, LatLng destination) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude < destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude > destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
    );

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _searchLocation(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
        });
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'VolunteerApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;

        setState(() {
          _searchResults = data.map((item) {
            return {
              'name': item['display_name'] ?? '',
              'lat': double.tryParse(item['lat'] ?? '0') ?? 0.0,
              'lng': double.tryParse(item['lon'] ?? '0') ?? 0.0,
              'type': item['type'] ?? '',
            };
          }).toList();
          _isSearching = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;
    final name = result['name'] as String;

    setState(() {
      _selectedLocation = LatLng(lat, lng);
      _showSearchResults = false;
      _searchController.text = name.split(',').first;

      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          infoWindow: InfoWindow(title: name.split(',').first),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      };
    });

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _selectedLocation!, zoom: 16),
      ),
    );

    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _showSearchResults = false;
      _markers = {};
      _selectedLocation = null;
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location services are disabled. Please turn on GPS.',
            style: AppTheme.mainFont(),
          ),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

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
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Fetch relief centers from the backend and create markers
  Future<void> _fetchReliefCenters() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/public/relief-centers'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List centers = data['message'];
          final Set<Marker> loadedMarkers = {};

          for (var center in centers) {
            // Check if location and coordinates exist
            // Backend schema: location: { type: 'Point', coordinates: [lon, lat] }
            if (center['address'] != null &&
                center['address']['location'] != null &&
                center['address']['location']['coordinates'] != null) {
              final coordinates = center['address']['location']['coordinates'];
              final double lon = (coordinates[0] as num).toDouble();
              final double lat = (coordinates[1] as num).toDouble();

              loadedMarkers.add(
                Marker(
                  markerId: MarkerId(
                    'relief_${center['_id'] ?? center['shelterName']}',
                  ),
                  position: LatLng(lat, lon),
                  infoWindow: InfoWindow(
                    title: center['shelterName'],
                    snippet: "Tap for details",
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                  onTap: () => _showReliefCenterDetails(center, lat, lon),
                ),
              );
            }
          }

          if (!mounted) return;
          setState(() {
            _reliefCenterMarkers = loadedMarkers;
          });
        }
      } else {
        debugPrint('Failed to load relief centers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching relief centers: $e');
    }
  }

  /// Launch phone dialer
  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch dialer',
              style: AppTheme.mainFont(),
            ),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Launch Google Maps for directions
  Future<void> _launchMaps(double lat, double lon, String? name) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon${name != null ? '($name)' : ''}',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps', style: AppTheme.mainFont()),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Show relief center details in a bottom sheet
  void _showReliefCenterDetails(
    Map<String, dynamic> center,
    double lat,
    double lon,
  ) {
    final address = center['address'] ?? {};
    final parts = [
      address['addressLine1'],
      address['addressLine2'],
      address['addressLine3'],
    ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
    final pin = address['pinCode'] != null ? ' - ${address['pinCode']}' : '';
    final fullAddress = '$parts$pin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppTheme.mediumShadow,
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    center['shelterName'] ?? 'Relief Center',
                    style: AppTheme.mainFont(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      fullAddress.isNotEmpty
                          ? fullAddress
                          : 'Address details not available',
                      style: AppTheme.mainFont(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Coordinator info
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: center['coordinatorNumber'] != null
                      ? () => _launchDialer(center['coordinatorNumber'])
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.surfaceColor,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppTheme.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COORDINATOR',
                                style: AppTheme.mainFont(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                center['coordinatorName'] ?? 'N/A',
                                style: AppTheme.mainFont(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (center['coordinatorNumber'] != null)
                                Text(
                                  center['coordinatorNumber'],
                                  style: AppTheme.mainFont(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (center['coordinatorNumber'] != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.phone_rounded,
                              color: AppTheme.successColor,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Get Directions button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _launchMaps(lat, lon, center['shelterName']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.directions_rounded, size: 20),
                label: Text(
                  'Get Directions',
                  style: AppTheme.mainFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading map...',
                    style: AppTheme.mainFont(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Google Map
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition,
                      zoom: 14.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                      if (_currentPosition.latitude != 37.7749) {
                        controller.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: _currentPosition, zoom: 15),
                          ),
                        );
                      }
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: _showReliefCenters
                        ? {..._markers, ..._reliefCenterMarkers}
                        : _markers,
                    polylines: _polylines,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    onTap: (_) {
                      setState(() {
                        _showSearchResults = false;
                      });
                      _searchFocusNode.unfocus();
                    },
                  ),
                ),

                // Navigation Info Bar (when showing route)
                if (widget.showNavigation && _routeDistance.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildNavigationInfoBar(),
                  ),

                // Search Bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Search Input
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.mediumShadow,
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: AppTheme.mainFont(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for a location...',
                            hintStyle: AppTheme.mainFont(
                              color: AppTheme.textMuted,
                              fontSize: 15,
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(14),
                              child: Icon(
                                Icons.search_rounded,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: AppTheme.textMuted,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onTap: () {
                            if (_searchResults.isNotEmpty) {
                              setState(() {
                                _showSearchResults = true;
                              });
                            }
                          },
                        ),
                      ),

                      // Search Results Dropdown
                      if (_showSearchResults)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.mediumShadow,
                          ),
                          child: _isSearching
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                )
                              : _searchResults.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_off_rounded,
                                          color: AppTheme.textMuted,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No locations found',
                                          style: AppTheme.mainFont(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      final result = _searchResults[index];
                                      return _buildSearchResultItem(
                                        result,
                                        index == _searchResults.length - 1,
                                      );
                                    },
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),

                // My Location Button
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.mediumShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: _currentPosition,
                                zoom: 15,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.my_location_rounded,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Zoom Controls
                Positioned(
                  right: 16,
                  bottom: 170,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            onTap: () {
                              mapController?.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.add_rounded,
                                color: AppTheme.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 1,
                          width: 30,
                          color: AppTheme.backgroundColor,
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            onTap: () {
                              mapController?.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.remove_rounded,
                                color: AppTheme.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Relief Centers Toggle Button
                Positioned(
                  right: 16,
                  bottom: 250,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _showReliefCenters
                          ? AppTheme.successColor
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.mediumShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _showReliefCenters = !_showReliefCenters;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.home_rounded,
                            color: _showReliefCenters
                                ? Colors.white
                                : AppTheme.successColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result, bool isLast) {
    final name = result['name'] as String;
    final parts = name.split(',');
    final title = parts.first.trim();
    final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectSearchResult(result),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: AppTheme.backgroundColor,
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.mainFont(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: AppTheme.mainFont(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.north_west_rounded,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the navigation info bar showing distance and duration
  Widget _buildNavigationInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Row(
        children: [
          // Distance
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.route_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _routeDistance,
                  style: AppTheme.mainFont(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _routeDuration,
                  style: AppTheme.mainFont(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Directions button
          Material(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showDirectionsBottomSheet(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Steps',
                      style: AppTheme.mainFont(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show bottom sheet with step-by-step directions
  void _showDirectionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.directions, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Directions',
                      style: AppTheme.mainFont(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$_routeDistance • $_routeDuration',
                      style: AppTheme.mainFont(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Steps list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _directionSteps.length,
                  itemBuilder: (context, index) {
                    final step = _directionSteps[index];
                    return _buildDirectionStep(step, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a single direction step item
  Widget _buildDirectionStep(Map<String, dynamic> step, int index) {
    final instruction = step['instruction'] as String;
    final distance = step['distance'] as String;
    final maneuver = step['maneuver'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number or maneuver icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: maneuver.isNotEmpty
                  ? Text(
                      NavigationService.getManeuverIcon(maneuver),
                      style: const TextStyle(fontSize: 18),
                    )
                  : Text(
                      '${index + 1}',
                      style: AppTheme.mainFont(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Instruction text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction,
                  style: AppTheme.mainFont(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distance,
                  style: AppTheme.mainFont(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
