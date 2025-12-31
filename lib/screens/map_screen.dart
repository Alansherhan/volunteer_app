import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:volunteer_app/env.dart';
import 'package:volunteer_app/theme/app_theme.dart';

class Map_Screen extends StatefulWidget {
  const Map_Screen({super.key});

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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
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
                    markers: _markers,
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
}
