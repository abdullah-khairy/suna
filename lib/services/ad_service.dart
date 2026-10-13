import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// خدمة إدارة الإعلانات للتطبيق (Google AdMob للموبايل و Google AdSense للويب)
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// تفعيل أو تعطيل الإعلانات في التطبيق بالكامل
  static bool isAdsEnabled = true;

  /// معرفات حساب Google AdSense للويب
  /// قم باستبدالها بمعرفاتك الحقيقية من لوحة تحكم AdSense
  static const String adSenseClientId = 'pub-6005902291034766';
  static const String adSenseBannerSlotId = 'f08c47fec0942fa0';

  /// معرفات Google AdMob للموبايل
  /// معرفات الاختبار الرسمية من Google (تضمن عدم إيقاف الحساب أثناء التطوير والتجربة)
  /// عند النشر على المتاجر، قم باستبدالها بمعرفات الوحدات الحقيقية
  static const String androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';

  /// المعرفات الإنتاجية (ضع معرفات وحداتك الحقيقية هنا)
  static const String androidProductionBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String iosProductionBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ';

  /// تحديد ما إذا كان التطبيق في وضع التجربة (Test Mode)
  static const bool isTestMode = true;

  /// الحصول على معرّف وحدة البانر المناسب للمنصة الحالية
  static String get bannerAdUnitId {
    if (kIsWeb) return '';

    if (Platform.isAndroid) {
      return isTestMode ? androidTestBannerId : androidProductionBannerId;
    } else if (Platform.isIOS) {
      return isTestMode ? iosTestBannerId : iosProductionBannerId;
    }
    return '';
  }

  /// تهيئة SDK للإعلانات عند بدء التطبيق
  Future<void> initialize() async {
    if (!isAdsEnabled) return;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await MobileAds.instance.initialize();
        debugPrint('Google Mobile Ads (AdMob) initialized successfully');
      } catch (e) {
        debugPrint('AdMob initialization error: $e');
      }
    } else if (kIsWeb) {
      debugPrint('Google AdSense configured for Web platform');
    }
  }
}
