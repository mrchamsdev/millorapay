import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAddressFormatting(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final name = place.name ?? '';
        final street = place.street ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';
        final adminArea = place.administrativeArea ?? '';
        final postalCode = place.postalCode ?? '';
        final country = place.country ?? '';

        final parts = <String>[];
        if (street.isNotEmpty) {
          parts.add(street);
        } else if (name.isNotEmpty) {
          parts.add(name);
        }
        if (subLocality.isNotEmpty && !parts.contains(subLocality)) {
          parts.add(subLocality);
        }
        if (locality.isNotEmpty && !parts.contains(locality)) {
          parts.add(locality);
        }
        if (adminArea.isNotEmpty && !parts.contains(adminArea)) {
          parts.add(adminArea);
        }
        if (postalCode.isNotEmpty) {
          parts.add(postalCode);
        }
        if (country.isNotEmpty && !parts.contains(country)) {
          parts.add(country);
        }

        return parts.join(', ');
      }
    } catch (_) {}
    return null;
  }
}
