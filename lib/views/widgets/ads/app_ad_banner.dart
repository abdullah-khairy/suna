import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../services/ad_service.dart';
import 'ad_web_bridge.dart';

enum AdPlacement {
  feedInline,
  bottomAnchor,
  detailsBottom,
}

/// ويدجت موحد لعرض إعلانات Google AdMob (على الموبايل) و Google AdSense (على الويب)
/// مصمم ليكون أنيقاً وفي مواضع غير مزعجة للمستخدمين
class AppAdBanner extends StatefulWidget {
  final AdPlacement placement;
  final EdgeInsetsGeometry? margin;
  final bool showLabel;

  const AppAdBanner({
    super.key,
    this.placement = AdPlacement.feedInline,
    this.margin,
    this.showLabel = true,
  });

  @override
  State<AppAdBanner> createState() => _AppAdBannerState();
}

class _AppAdBannerState extends State<AppAdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadMobileBanner();
  }

  void _loadMobileBanner() {
    if (!AdService.isAdsEnabled || kIsWeb) return;

    if (Platform.isAndroid || Platform.isIOS) {
      final adUnitId = AdService.bannerAdUnitId;
      if (adUnitId.isEmpty) return;

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: widget.placement == AdPlacement.feedInline
            ? AdSize.largeBanner // 320x100
            : AdSize.banner, // 320x50
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
                _isAdFailed = false;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAd failed to load: ${error.message}');
            ad.dispose();
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
                _isAdFailed = true;
              });
            }
          },
        ),
      );

      _bannerAd?.load();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.isAdsEnabled || _isDismissed) {
      return const SizedBox.shrink();
    }

    // 1. معالجة الويب (Google AdSense)
    if (kIsWeb) {
      return _buildWebAdSenseView();
    }

    // 2. معالجة سطح المكتب (Windows / macOS / Linux)
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const SizedBox.shrink();
    }

    // 3. معالجة الموبايل (Google AdMob)
    if (_isAdFailed || (!_isAdLoaded && _bannerAd != null)) {
      // إخفاء المساحة تماماً إذا لم يتم تحميل الإعلان لتجنب الفراغات المزعجة
      return const SizedBox.shrink();
    }

    if (_bannerAd == null || !_isAdLoaded) {
      return const SizedBox.shrink();
    }

    return _wrapAdWithContainer(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }

  Widget _buildWebAdSenseView() {
    final screenWidth = MediaQuery.of(context).size.width;
    double adWidth = (screenWidth > 768) ? 728 : (screenWidth - 32).clamp(300, 468);
    double adHeight = (screenWidth > 768) ? 90 : 60;

    return _wrapAdWithContainer(
      child: buildAdSenseWebContainer(
        clientId: AdService.adSenseClientId,
        slotId: AdService.adSenseBannerSlotId,
        width: adWidth,
        height: adHeight,
        isTestMode: AdService.isTestMode,
      ),
    );
  }

  Widget _wrapAdWithContainer({required Widget child}) {
    final isBottomAnchor = widget.placement == AdPlacement.bottomAnchor;

    return Container(
      margin: widget.margin ??
          (isBottomAnchor
              ? const EdgeInsets.only(top: 4, bottom: 4)
              : const EdgeInsets.symmetric(vertical: 8, horizontal: 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isBottomAnchor ? 0 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showLabel)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'إعلان ممول',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kIsWeb ? 'Google AdSense' : 'Google AdMob',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (widget.placement == AdPlacement.bottomAnchor)
                    InkWell(
                      onTap: () => setState(() => _isDismissed = true),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(Icons.close, size: 13, color: Colors.grey.shade400),
                      ),
                    ),
                ],
              ),
            ),
          Center(child: child),
          const SizedBox(height: 3),
        ],
      ),
    );
  }
}
