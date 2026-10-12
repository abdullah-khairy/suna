import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

class LocationService {
  static final Location _location = Location();

  /// طلب الأذونات والحصول على الموقع الحالي
  static Future<GeoPoint?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }

      final locationData = await _location.getLocation();
      return GeoPoint(locationData.latitude, locationData.longitude);
    } catch (_) {
      // التعامل الآمن مع تعذر جلب الموقع
    }
    return null;
  }

  /// حساب المسافة بالكيلومتر بين نقطتين جغرافيتين (معادلة Haversine)
  static double calculateDistanceInKm(GeoPoint point1, GeoPoint point2) {
    const double earthRadiusKm = 6371.0;

    double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    double dLon = _degreesToRadians(point2.longitude - point1.longitude);

    double lat1Rad = _degreesToRadians(point1.latitude);
    double lat2Rad = _degreesToRadians(point2.latitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1Rad) * cos(lat2Rad);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// نص منسق لعرض المسافة
  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} متر';
    }
    return '${km.toStringAsFixed(1)} كم';
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }
}
