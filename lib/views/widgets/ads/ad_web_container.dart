import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

int _adSenseViewCounter = 0;

Widget buildAdSenseWebContainer({required String clientId, required String slotId, required double width, required double height, required bool isTestMode}) {
  if (isTestMode) {
    return _buildTestAdSenseCard(width: width, height: height, slotId: slotId);
  }

  return _AdSenseWebContainer(clientId: clientId, slotId: slotId, width: width, height: height);
}

class _AdSenseWebContainer extends StatefulWidget {
  const _AdSenseWebContainer({required this.clientId, required this.slotId, required this.width, required this.height});

  final String clientId;
  final String slotId;
  final double width;
  final double height;

  @override
  State<_AdSenseWebContainer> createState() => _AdSenseWebContainerState();
}

class _AdSenseWebContainerState extends State<_AdSenseWebContainer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'adsense-banner-${_adSenseViewCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _createAdElement());
  }

  web.HTMLElement _createAdElement() {
    _ensureAdSenseScript(widget.clientId);

    final container = web.document.createElement('div') as web.HTMLElement;
    container.style
      ..width = '100%'
      ..height = '100%'
      ..display = 'flex'
      ..justifyContent = 'center'
      ..alignItems = 'center'
      ..overflow = 'hidden';

    final ad = web.document.createElement('ins') as web.HTMLElement;
    ad.className = 'adsbygoogle';
    ad.style
      ..display = 'inline-block'
      ..width = '${widget.width.toInt()}px'
      ..height = '${widget.height.toInt()}px';
    ad.setAttribute('data-ad-client', widget.clientId);
    ad.setAttribute('data-ad-slot', widget.slotId);
    container.append(ad);

    return container;
  }

  void _onPlatformViewCreated(int viewId) {
    final pushScript = web.document.createElement('script') as web.HTMLScriptElement;
    pushScript.text = '(window.adsbygoogle = window.adsbygoogle || []).push({});';
    web.document.body!.append(pushScript);
    pushScript.remove();
  }

  void _ensureAdSenseScript(String clientId) {
    final existingScript = web.document.querySelector('script[data-adsense-client="$clientId"]');
    if (existingScript != null) return;

    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.async = true;
    script.src =
        'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'
        '?client=${Uri.encodeQueryComponent(clientId)}';
    script.setAttribute('crossorigin', 'anonymous');
    script.setAttribute('data-adsense-client', clientId);
    web.document.head?.append(script);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType, onPlatformViewCreated: _onPlatformViewCreated),
    );
  }
}

Widget _buildTestAdSenseCard({required double width, required double height, required String slotId}) {
  return Container(
    width: width,
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300, width: 1),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(4)),
          child: const Text(
            'إعلان',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.ads_click, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'مساحة Google AdSense للويب (Slot: $slotId)',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
