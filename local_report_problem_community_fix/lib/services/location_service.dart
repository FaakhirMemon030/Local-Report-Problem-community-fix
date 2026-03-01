import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class AddressInfo {
  final String fullAddress;
  final String city;
  final String district;
  final String road;

  AddressInfo({
    required this.fullAddress, 
    required this.city, 
    required this.district, 
    required this.road
  });

  factory AddressInfo.fromCoords(double lat, double lng) {
    return AddressInfo(
      fullAddress: "Coords: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}",
      city: "Unknown",
      district: "",
      road: "Unknown Road",
    );
  }
}

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

  Future<AddressInfo> getAddressFromLatLng(LatLng position) async {
    // Try native geocoding first (Mobile)
    if (!kIsWeb) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks[0];
          return AddressInfo(
            fullAddress: "${p.street}, ${p.locality}, ${p.administrativeArea}".replaceAll(", null", ""),
            city: p.locality ?? p.subAdministrativeArea ?? "Unknown",
            district: p.subAdministrativeArea ?? "",
            road: p.street ?? "Unknown Road",
          );
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
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        
        String city = addr['city'] ?? addr['town'] ?? addr['village'] ?? "Unknown";
        String road = addr['road'] ?? addr['neighbourhood'] ?? addr['suburb'] ?? "Unknown Road";
        String district = addr['city_district'] ?? addr['county'] ?? "";

        return AddressInfo(
          fullAddress: data['display_name'] ?? "Unknown Location",
          city: city,
          district: district,
          road: road,
        );
      } else {
        print("LPRCF: Nominatim error ${response.statusCode}");
      }
    } catch (e) {
      print('LPRCF: Nominatim exception: $e');
    }

    return AddressInfo.fromCoords(position.latitude, position.longitude);
  }
}
