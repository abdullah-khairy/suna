import 'package:cloud_firestore/cloud_firestore.dart';

class CountryCurrencyInfo {
  final String code;
  final String name;
  final String currency;
  final String currencyName;
  final String flag;
  final String phonePrefix;

  const CountryCurrencyInfo({
    required this.code,
    required this.name,
    required this.currency,
    required this.currencyName,
    required this.flag,
    required this.phonePrefix,
  });
}

class CurrencyHelper {
  static const CountryCurrencyInfo saudiArabia = CountryCurrencyInfo(
    code: 'SA',
    name: 'السعودية',
    currency: 'ر.س',
    currencyName: 'ريال سعودي',
    flag: '🇸🇦',
    phonePrefix: '+966',
  );

  static const CountryCurrencyInfo egypt = CountryCurrencyInfo(
    code: 'EG',
    name: 'مصر',
    currency: 'ج.م',
    currencyName: 'جنيه مصري',
    flag: '🇪🇬',
    phonePrefix: '+20',
  );

  static const CountryCurrencyInfo uae = CountryCurrencyInfo(
    code: 'AE',
    name: 'الإمارات',
    currency: 'د.إ',
    currencyName: 'درهم إماراتي',
    flag: '🇦🇪',
    phonePrefix: '+971',
  );

  static const CountryCurrencyInfo kuwait = CountryCurrencyInfo(
    code: 'KW',
    name: 'الكويت',
    currency: 'د.ك',
    currencyName: 'دينار كويتي',
    flag: '🇰🇼',
    phonePrefix: '+965',
  );

  static const CountryCurrencyInfo qatar = CountryCurrencyInfo(
    code: 'QA',
    name: 'قطر',
    currency: 'ر.ق',
    currencyName: 'ريال قطري',
    flag: '🇶🇦',
    phonePrefix: '+974',
  );

  static const CountryCurrencyInfo bahrain = CountryCurrencyInfo(
    code: 'BH',
    name: 'البحرين',
    currency: 'د.ب',
    currencyName: 'دينار بحريني',
    flag: '🇧🇭',
    phonePrefix: '+973',
  );

  static const CountryCurrencyInfo oman = CountryCurrencyInfo(
    code: 'OM',
    name: 'عُمان',
    currency: 'ر.ع',
    currencyName: 'ريال عماني',
    flag: '🇴🇲',
    phonePrefix: '+968',
  );

  static const CountryCurrencyInfo jordan = CountryCurrencyInfo(
    code: 'JO',
    name: 'الأردن',
    currency: 'د.أ',
    currencyName: 'دينار أردني',
    flag: '🇯🇴',
    phonePrefix: '+962',
  );

  static const CountryCurrencyInfo iraq = CountryCurrencyInfo(
    code: 'IQ',
    name: 'العراق',
    currency: 'د.ع',
    currencyName: 'دينار عراقي',
    flag: '🇮🇶',
    phonePrefix: '+964',
  );

  static const List<CountryCurrencyInfo> supportedCountries = [
    saudiArabia,
    egypt,
    uae,
    kuwait,
    qatar,
    bahrain,
    oman,
    jordan,
    iraq,
  ];

  static CountryCurrencyInfo get defaultCountry => saudiArabia;

  /// تحديد الدولة والعملة بذكاء بناءً على الإحداثيات أو رقم الهاتف أو العنوان
  static CountryCurrencyInfo detectCountry({
    GeoPoint? location,
    String? phone,
    String? address,
  }) {
    // 1. الفحص الدقيق بناءً على الإحداثيات الجغرافية (بدون الحاجة لإنترنت أو واجهات مدفوعة)
    if (location != null) {
      final lat = location.latitude;
      final lng = location.longitude;

      // جمهورية مصر العربية
      if (lat >= 21.8 && lat <= 32.0 && lng >= 24.5 && lng <= 37.0) {
        return egypt;
      }
      // البحرين
      if (lat >= 25.7 && lat <= 26.4 && lng >= 50.3 && lng <= 50.8) {
        return bahrain;
      }
      // قطر
      if (lat >= 24.5 && lat <= 26.3 && lng >= 50.7 && lng <= 51.7) {
        return qatar;
      }
      // الكويت
      if (lat >= 28.5 && lat <= 30.2 && lng >= 46.5 && lng <= 48.6) {
        return kuwait;
      }
      // الإمارات
      if (lat >= 22.5 && lat <= 26.2 && lng >= 51.5 && lng <= 56.5) {
        return uae;
      }
      // سلطنة عمان
      if (lat >= 16.5 && lat <= 26.4 && lng >= 52.0 && lng <= 60.0) {
        return oman;
      }
      // الأردن
      if (lat >= 29.2 && lat <= 33.4 && lng >= 34.8 && lng <= 39.3) {
        return jordan;
      }
      // العراق
      if (lat >= 29.0 && lat <= 37.5 && lng >= 38.7 && lng <= 48.7) {
        return iraq;
      }
      // المملكة العربية السعودية
      if (lat >= 16.0 && lat <= 32.5 && lng >= 34.5 && lng <= 55.8) {
        return saudiArabia;
      }
    }

    // 2. الفحص بناءً على رقم الهاتف ومفتاح الدولة
    if (phone != null && phone.trim().isNotEmpty) {
      final p = phone.trim().replaceAll(' ', '').replaceAll('-', '');
      if (p.startsWith('+20') || p.startsWith('0020') || p.startsWith('01')) {
        return egypt;
      }
      if (p.startsWith('+966') || p.startsWith('00966') || p.startsWith('05')) {
        return saudiArabia;
      }
      if (p.startsWith('+971') || p.startsWith('00971')) return uae;
      if (p.startsWith('+965') || p.startsWith('00965')) return kuwait;
      if (p.startsWith('+974') || p.startsWith('00974')) return qatar;
      if (p.startsWith('+973') || p.startsWith('00973')) return bahrain;
      if (p.startsWith('+968') || p.startsWith('00968')) return oman;
      if (p.startsWith('+962') || p.startsWith('00962')) return jordan;
      if (p.startsWith('+964') || p.startsWith('00964')) return iraq;
    }

    // 3. الفحص بناءً على الكلمات المفتاحية في العنوان
    if (address != null && address.trim().isNotEmpty) {
      final a = address.toLowerCase();
      if (a.contains('مصر') ||
          a.contains('القاهرة') ||
          a.contains('الجيزة') ||
          a.contains('الإسكندرية') ||
          a.contains('اسكندرية') ||
          a.contains('المنصورة') ||
          a.contains('طنطا') ||
          a.contains('شبرا') ||
          a.contains('المعادي') ||
          a.contains('أكتوبر') ||
          a.contains('فيصل') ||
          a.contains('الهرم') ||
          a.contains('التجمع')) {
        return egypt;
      }
      if (a.contains('السعودية') ||
          a.contains('الرياض') ||
          a.contains('جدة') ||
          a.contains('مكة') ||
          a.contains('المدينة') ||
          a.contains('الدمام') ||
          a.contains('الخبر') ||
          a.contains('القصيم') ||
          a.contains('أبها') ||
          a.contains('تبوك') ||
          a.contains('حائل')) {
        return saudiArabia;
      }
      if (a.contains('الإمارات') || a.contains('دبي') || a.contains('أبوظبي') || a.contains('الشارقة')) {
        return uae;
      }
      if (a.contains('الكويت')) return kuwait;
      if (a.contains('قطر') || a.contains('الدوحة')) return qatar;
      if (a.contains('البحرين') || a.contains('المنامة')) return bahrain;
      if (a.contains('عمان') || a.contains('مسقط')) return oman;
      if (a.contains('الأردن') || a.contains('عمان') || a.contains('إربد')) return jordan;
      if (a.contains('العراق') || a.contains('بغداد') || a.contains('البصرة')) return iraq;
    }

    return defaultCountry;
  }

  /// إرجاع رمز العملة المحلي مباشرة (مثال: ر.س أو ج.م)
  static String resolveCurrency({
    GeoPoint? location,
    String? phone,
    String? address,
    String? fallbackCurrency,
  }) {
    if (fallbackCurrency != null && fallbackCurrency.trim().isNotEmpty) {
      return fallbackCurrency.trim();
    }
    return detectCountry(location: location, phone: phone, address: address).currency;
  }

  /// البحث عن دولة بناءً على كود الدولة أو العملة
  static CountryCurrencyInfo findByCurrencyOrCode(String query) {
    final q = query.trim().toLowerCase();
    for (var c in supportedCountries) {
      if (c.code.toLowerCase() == q ||
          c.currency.toLowerCase() == q ||
          c.name.toLowerCase() == q) {
        return c;
      }
    }
    return defaultCountry;
  }
}
