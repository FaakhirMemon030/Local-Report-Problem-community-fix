import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LocationService {
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("LPRCF: Location services are disabled.");
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("LPRCF: Location permissions are denied.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("LPRCF: Location permissions are permanently denied.");
        return null;
      }

      print("LPRCF: Fetching current position...");
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print("LPRCF: Error in getCurrentLocation: $e");
      return null;
    }
  }

  Future<String?> getAddressFromLatLng(LatLng position) async {
    // Try native geocoding first (Mobile)
    if (!kIsWeb) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks[0];
          return "${p.street}, ${p.locality}, ${p.administrativeArea}".replaceAll(", null", "");
        }
      } catch (e) {
        print('LPRCF: Native geocoding error: $e');
      }
    }

    // Fallback/Web: Use Nominatim (OpenStreetMap)
    try {
      print("LPRCF: Attempting Nominatim reverse geocoding...");
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'LPRCF_Civic_Reporter_App'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? "Unknown Location";
      } else {
        print("LPRCF: Nominatim error ${response.statusCode}");
      }
    } catch (e) {
      print('LPRCF: Nominatim exception: $e');
    }

    return "Coords: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
  }
}
