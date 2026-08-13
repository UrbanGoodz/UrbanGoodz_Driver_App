import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:urban_goodz_driver/models/purchase_card_model.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

/// Thin wrapper over the platform channel that toggles FLAG_SECURE.
///
/// Failures are swallowed on purpose: on a platform where the channel is not
/// implemented the reveal must still work, it simply does not get the extra
/// screenshot protection.
class SecureScreen {
  static const MethodChannel _channel = MethodChannel(
    'com.urbangoodz.driver/secure_screen',
  );

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod<bool>('enable');
    } on PlatformException {
      // Best-effort hardening only.
    } on MissingPluginException {
      // Not available on this platform (tests, desktop).
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<bool>('disable');
    } on PlatformException {
      // Best-effort hardening only.
    } on MissingPluginException {
      // Not available on this platform (tests, desktop).
    }
  }
}

/// Displays the provider-hosted card reveal page.
///
/// Card credentials are rendered by the provider inside the WebView and are
/// never read into Dart: there is no JavaScript channel, no page-content
/// extraction and no logging of the session URL. The screen closes itself when
/// the session expires or the app leaves the foreground.
class SecureCardRevealScreen extends StatefulWidget {
  const SecureCardRevealScreen({
    super.key,
    required this.session,
    this.webViewBuilder,
  });

  final CardRevealSession session;

  /// Test seam. When supplied, this widget stands in for the platform WebView
  /// so the concealment and expiry behaviour can be exercised without an
  /// Android/iOS webview implementation. Production leaves it null.
  final Widget Function()? webViewBuilder;

  @override
  State<SecureCardRevealScreen> createState() => _SecureCardRevealScreenState();
}

class _SecureCardRevealScreenState extends State<SecureCardRevealScreen>
    with WidgetsBindingObserver {
  WebViewController? _webController;
  Timer? _expiryTimer;

  /// Set when the app leaves the foreground. While true the WebView is
  /// replaced by an opaque cover so nothing sensitive can be captured.
  bool _concealed = false;

  bool _expired = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SecureScreen.enable();

    if (widget.session.isExpired) {
      _expired = true;
      _loading = false;
    } else {
      _startExpiryCountdown();
      if (widget.webViewBuilder == null) {
        _initWebView();
      } else {
        _loading = false;
      }
    }
  }

  void _initWebView() {
    final controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            // The error object can echo the session URL, so nothing from it is
            // logged or shown; the driver gets generic wording instead.
            if (mounted) {
              setState(() {
                _loading = false;
                _expired = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.session.revealUrl));
    _webController = controller;
  }

  /// Closes the view the moment the server-side session lapses, rather than
  /// leaving a dead page that still looks live.
  void _startExpiryCountdown() {
    final expiry = widget.session.expiresAt;
    if (expiry == null) return;
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) {
      _expired = true;
      return;
    }
    _expiryTimer = Timer(remaining, () {
      if (mounted) setState(() => _expired = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // inactive fires before paused and covers the app-switcher snapshot, so
    // concealment happens before anything can be captured.
    final leaving =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;

    if (leaving && !_concealed) {
      setState(() => _concealed = true);
    } else if (state == AppLifecycleState.resumed && _concealed) {
      // The session is not re-opened automatically: the driver must ask again,
      // which forces a fresh short-lived session rather than reusing a stale
      // one that may have been left open on a lost phone.
      setState(() {
        _concealed = false;
        _expired = true;
      });
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SecureScreen.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Secure Card Details'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('secure_reveal_close'),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_concealed) return _cover();
    if (_expired) return _expiredView();

    final builder = widget.webViewBuilder;
    if (builder != null) {
      return KeyedSubtree(
        key: const Key('secure_reveal_webview'),
        child: builder(),
      );
    }

    final controller = _webController;
    if (controller == null) return _expiredView();

    return Stack(
      children: [
        WebViewWidget(
          key: const Key('secure_reveal_webview'),
          controller: controller,
        ),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }

  /// Opaque overlay shown whenever the app is not in the foreground.
  Widget _cover() {
    return Container(
      key: const Key('secure_reveal_concealed'),
      color: Colors.black,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: Colors.white70, size: 56),
          SizedBox(height: 16),
          Text(
            'Card details hidden',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _expiredView() {
    return Center(
      key: const Key('secure_reveal_expired'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_outlined, color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            const Text(
              'This secure session has ended.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open secure details again from the purchase card screen to start a new session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back to card'),
            ),
          ],
        ),
      ),
    );
  }
}
