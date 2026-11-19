import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// An animated banner that slides down from the top of the screen whenever the
/// device loses network connectivity.
///
/// Wrap this around any widget that should show the offline indicator, typically
/// the root [Scaffold] body:
///
/// ```dart
/// Scaffold(
///   body: GFOfflineBanner(child: MyContent()),
/// )
/// ```
class GFOfflineBanner extends StatefulWidget {
  const GFOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  State<GFOfflineBanner> createState() => _GFOfflineBannerState();
}

class _GFOfflineBannerState extends State<GFOfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  static const Duration _animDuration = Duration(milliseconds: 300);
  static const double _bannerHeight = 44.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _animDuration);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);

    // Check initial state.
    Connectivity().checkConnectivity().then((results) {
      if (mounted) _onConnectivityChanged(results);
    });
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (offline == _isOffline) return;
    setState(() => _isOffline = offline);
    if (offline) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content — shift down when banner is visible so nothing is hidden.
        AnimatedPadding(
          duration: _animDuration,
          curve: Curves.easeOut,
          padding: EdgeInsets.only(top: _isOffline ? _bannerHeight : 0),
          child: widget.child,
        ),

        // Offline banner.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _OfflineBannerContent(height: _bannerHeight),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineBannerContent extends StatelessWidget {
  const _OfflineBannerContent({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF212121),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                'No connection \u2022 Changes will sync when back online',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
