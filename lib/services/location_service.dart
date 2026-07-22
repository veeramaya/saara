import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

/// §8 foreground location + geocoding. Used to resolve a task's place to
/// coordinates for a geofence, and to read the current position. Background
/// ("all the time") permission is requested only when a geofence is enabled.
class LocationService {
  const LocationService();

  Future<LocationPermission> _ensure() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermission.denied;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p;
  }

  Future<bool> ensureForeground() async {
    final p = await _ensure();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// Escalate to background ("Allow all the time") so a geofence fires while the
  /// app is closed. Returns true only if granted.
  Future<bool> ensureBackground() async {
    var p = await _ensure();
    if (p == LocationPermission.whileInUse) {
      p = await Geolocator.requestPermission(); // Android escalates to always
    }
    return p == LocationPermission.always;
  }

  Future<({double lat, double lng})?> currentLatLng() async {
    if (!await ensureForeground()) return null;
    try {
      final pos = await Geolocator.getCurrentPosition();
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Forward-geocode a typed place ("Apollo Clinic, Whitefield") to coordinates.
  Future<({double lat, double lng})?> geocode(String address) async {
    try {
      final r = await geo.locationFromAddress(address);
      if (r.isEmpty) return null;
      return (lat: r.first.latitude, lng: r.first.longitude);
    } catch (_) {
      return null;
    }
  }
}
