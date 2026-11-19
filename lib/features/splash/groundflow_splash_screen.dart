import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/state/ground_flow_realtime_store.dart';
import '../auth/groundflow_login_screen.dart';
import '../home/global_brand_home_screen.dart';

class GroundFlowSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const GroundFlowSplashScreen({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<GroundFlowSplashScreen> createState() => _GroundFlowSplashScreenState();
}

class _GroundFlowSplashScreenState extends State<GroundFlowSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _logoRotateAnim;
  late Animation<double> _titleFadeAnim;
  late Animation<Offset> _titleSlideAnim;
  late Animation<double> _progressAnim;

  final GroundFlowRealtimeStore _store = GroundFlowRealtimeStore();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    _logoRotateAnim = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _titleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleTransition();
      }
    });

    _controller.forward();
  }

  void _handleTransition() {
    if (!mounted) return;
    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    } else {
      if (_store.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => GlobalBrandHomeScreen(
              onSignOut: () {
                _store.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => GroundFlowLoginScreen(
                      onLoginSuccess: () {},
                    ),
                  ),
                );
              },
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => GroundFlowLoginScreen(
              onLoginSuccess: () {},
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Radial Glow Backdrop
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      GlassTheme.accentSky.withValues(alpha: 0.14),
                      const Color(0xFF6366F1).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Main Center Content: Animated Logo & Brand Name
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Brand Logo Mark
                    FadeTransition(
                      opacity: _logoFadeAnim,
                      child: ScaleTransition(
                        scale: _logoScaleAnim,
                        child: RotationTransition(
                          turns: _logoRotateAnim,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: GlassTheme.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: GlassTheme.accentSky
                                      .withValues(alpha: 0.35),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.hub_rounded,
                                color: Colors.black,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Animated App Name & Subtitle
                    FadeTransition(
                      opacity: _titleFadeAnim,
                      child: SlideTransition(
                        position: _titleSlideAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'GroundFlow',
                              style: GoogleFonts.roboto(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: GlassTheme.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Event Operations & Automation Platform',
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: GlassTheme.mutedSilver,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Loading & Status Indicator
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _progressAnim.value;
                String statusText = 'Initializing GroundFlow...';
                if (progress > 0.45) {
                  statusText = 'Verifying security credentials...';
                }
                if (progress > 0.85) {
                  statusText = _store.isAuthenticated
                      ? (_store.userName.isNotEmpty
                          ? 'Welcome back, ${_store.userName}'
                          : 'Welcome back')
                      : 'Ready';
                }

                return FadeTransition(
                  opacity: _titleFadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Slim Loading Bar
                      Container(
                        width: 140,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  GlassTheme.accentSky,
                                  GlassTheme.accentEmerald,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: GlassTheme.accentSky
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status Text
                      Text(
                        statusText,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: GlassTheme.mutedSilver,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Version Tag
                      Text(
                        'v2.4.0',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: const Color(0xFF52525B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
