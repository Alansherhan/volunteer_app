import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for fetching routes and directions from Google Directions API
class NavigationService {
  // Using the same API key as configured in AndroidManifest.xml
  static const String _apiKey = 'AIzaSyA-iVr1hsRG4GSLpWksqxlmUAOsR-IRsdw';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Fetch route between two points
  /// Returns a map with 'polylinePoints', 'distance', 'duration', and 'steps'
  static Future<Map<String, dynamic>?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$mode'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Decode polyline
          final polylinePoints = _decodePolyline(
            route['overview_polyline']['points'],
          );

          // Parse steps
          final steps = <Map<String, dynamic>>[];
          for (var step in leg['steps']) {
            steps.add({
              'instruction': _stripHtmlTags(step['html_instructions']),
              'distance': step['distance']['text'],
              'duration': step['duration']['text'],
              'startLocation': LatLng(
                step['start_location']['lat'],
                step['start_location']['lng'],
              ),
              'endLocation': LatLng(
                step['end_location']['lat'],
                step['end_location']['lng'],
              ),
              'maneuver': step['maneuver'] ?? '',
            });
          }

          return {
            'polylinePoints': polylinePoints,
            'distance': leg['distance']['text'],
            'distanceValue': leg['distance']['value'], // in meters
            'duration': leg['duration']['text'],
            'durationValue': leg['duration']['value'], // in seconds
            'steps': steps,
            'startAddress': leg['start_address'],
            'endAddress': leg['end_address'],
          };
        }
      }

      return null;
    } catch (e) {
      print('Navigation error: $e');
      return null;
    }
  }

  /// Decode Google's encoded polyline format to list of LatLng
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Remove HTML tags from instruction strings
  static String _stripHtmlTags(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Get icon for maneuver type
  static String getManeuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return '↰';
      case 'turn-right':
        return '↱';
      case 'turn-slight-left':
        return '↖';
      case 'turn-slight-right':
        return '↗';
      case 'turn-sharp-left':
        return '⟲';
      case 'turn-sharp-right':
        return '⟳';
      case 'uturn-left':
      case 'uturn-right':
        return '↩';
      case 'straight':
        return '↑';
      case 'roundabout-left':
      case 'roundabout-right':
        return '⟲';
      case 'merge':
        return '⤵';
      case 'fork-left':
      case 'fork-right':
        return '⑂';
      case 'ferry':
        return '⛴';
      default:
        return '•';
    }
  }
}
