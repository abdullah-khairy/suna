import 'package:url_launcher/url_launcher.dart';

class ExternalLauncher {
  /// إجراء اتصال هاتفي مجاني ومباشر عبر تطبيق الاتصال بالهاتف
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        return await launchUrl(launchUri);
      }
    } catch (_) {}
    return false;
  }

  /// فتح خرائط جوجل مجاناً وبدون أي مفتاح API أو تكاليف
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
    String? title,
  }) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        return await launchUrl(
          googleMapsUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}
    return false;
  }
}
