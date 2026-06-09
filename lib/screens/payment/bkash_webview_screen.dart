import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants.dart';
import '../../services/payment_service.dart';

// ---------------------------------------------------------------------------
// BkashWebViewScreen
//
// Opens the bKash-hosted payment page in a WebView.
// Intercepts the callbackURL redirect to detect success/failure.
// On success: calls executePayment() and pops with the trxID string.
// On failure/cancel: pops with null.
//
// Usage:
//   final trxId = await Navigator.push<String>(
//     context,
//     MaterialPageRoute(
//       builder: (_) => BkashWebViewScreen(
//         bkashUrl: paymentResult.bkashUrl,
//         paymentId: paymentResult.paymentId,
//         bn: _bn,
//       ),
//     ),
//   );
//   if (trxId != null) { /* success */ }
// ---------------------------------------------------------------------------

class BkashWebViewScreen extends StatefulWidget {
  final String bkashUrl;
  final String paymentId;
  final bool bn;

  const BkashWebViewScreen({
    super.key,
    required this.bkashUrl,
    required this.paymentId,
    this.bn = true,
  });

  @override
  State<BkashWebViewScreen> createState() => _BkashWebViewScreenState();
}

class _BkashWebViewScreenState extends State<BkashWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _executed = false;

  String _t(String bn, String en) => widget.bn ? bn : en;

  static const _bkashPink = Color(0xFFE2136E);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: _handleNavigation,
          onWebResourceError: (err) {
            // ERR_UNKNOWN_URL_SCHEME (-1) fires when bKash tries to
            // launch its own app via deep link — this is expected, ignore it.
            if (err.errorCode == -1) return;
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.bkashUrl));
  }

  // -------------------------------------------------------------------------
  // Navigation intercept — catch callbackURL
  // -------------------------------------------------------------------------

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final url = request.url;

    // Catch our callback URL
    if (url.startsWith(AppConstants.bkashCallbackUrl)) {
      if (!_executed) {
        _executed = true;
        final uri = Uri.parse(url);
        final status = uri.queryParameters['status'];
        final paymentId = uri.queryParameters['paymentID'];

        if (status == 'success' && paymentId != null) {
          _onCallbackSuccess(paymentId);
        } else {
          _onCallbackFailure(status ?? 'failure');
        }
      }
      return NavigationDecision.prevent;
    }

    // Prevent WebView crash on bKash/market deep links
    if (url.startsWith('intent://') ||
        url.startsWith('bkash://') ||
        url.startsWith('market://')) {
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  // -------------------------------------------------------------------------
  // Success path — execute payment, get trxID, pop
  // -------------------------------------------------------------------------

  Future<void> _onCallbackSuccess(String paymentId) async {
    if (!mounted) return;
    setState(() => _loading = true);

    // Capture navigator and messenger before any await gap
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await BkashPaymentService().executePayment(paymentId);
      nav.pop(result.trxId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${_t('পেমেন্ট নিশ্চিত হয়নি', 'Payment confirmation failed')}: $e',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Small delay so user sees the snackbar before screen closes
      await Future.delayed(const Duration(seconds: 2));
      nav.pop(null);
    }
  }

  // -------------------------------------------------------------------------
  // Failure path
  // -------------------------------------------------------------------------

  void _onCallbackFailure(String reason) {
    if (!mounted) return;
    final nav = Navigator.of(context);
    final msg = reason == 'cancel'
        ? _t('পেমেন্ট বাতিল করা হয়েছে', 'Payment was cancelled')
        : _t('পেমেন্ট ব্যর্থ হয়েছে', 'Payment failed');
    _showSnack(msg, isError: true);
    Future.delayed(const Duration(seconds: 2), () {
      nav.pop(null);
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Close/cancel dialog
  // -------------------------------------------------------------------------

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('পেমেন্ট বাতিল?', 'Cancel payment?')),
        content: Text(
          _t(
            'আপনি কি নিশ্চিতভাবে পেমেন্ট বাতিল করতে চান?',
            'Are you sure you want to cancel this payment?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('না', 'No')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _t('হ্যাঁ, বাতিল করুন', 'Yes, cancel'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _onWillPop()) {
          nav.pop(null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _bkashPink,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              // bKash logo placeholder (pink bg + white text reads fine)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'bKash',
                  style: TextStyle(
                    color: _bkashPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _t('পেমেন্ট', 'Payment'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: _t('বাতিল করুন', 'Cancel'),
            onPressed: () async {
              final nav = Navigator.of(context);
              if (await _onWillPop()) {
                nav.pop(null);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              Container(
                color: Colors.white.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: _bkashPink,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _t('বিকাশ পেমেন্ট লোড হচ্ছে...', 'Loading bKash...'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
