import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

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
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      print("LPRCF: Error in getCurrentLocation: $e");
      return null;
    }
  }

  Future<Placemark?> getAddressFromLatLng(LatLng position) async {
    if (kIsWeb) {
      print('LPRCF: Geocoding (placemarkFromCoordinates) is not supported on Web.');
      return null;
    }
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) return placemarks[0];
    } catch (e) {
      print('LPRCF: Geocoding error: $e');
    }
    return null;
  }
}
