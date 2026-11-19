import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/glass_theme.dart';
import 'core/state/ground_flow_realtime_store.dart';
import 'core/auth/firebase_auth_service.dart';
import 'features/auth/groundflow_login_screen.dart';
import 'features/home/global_brand_home_screen.dart';
import 'features/splash/groundflow_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core & Auth services
  final authService = FirebaseAuthService();
  await authService.initFirebase();

  // Initialize GroundFlow persistent realtime store
  final store = GroundFlowRealtimeStore();
  await store.init();

  runApp(
    const ProviderScope(
      child: GroundFlowApp(),
    ),
  );
}

class GroundFlowApp extends StatefulWidget {
  const GroundFlowApp({super.key});

  @override
  State<GroundFlowApp> createState() => _GroundFlowAppState();
}

class _GroundFlowAppState extends State<GroundFlowApp> {
  final GroundFlowRealtimeStore _store = GroundFlowRealtimeStore();
  bool _showSplash = true;

  void _onSplashFinished() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GroundFlow',
      debugShowCheckedModeBanner: false,
      theme: GlassTheme.theme,
      home: _showSplash
          ? GroundFlowSplashScreen(
              onAnimationComplete: _onSplashFinished,
            )
          : ListenableBuilder(
              listenable: _store,
              builder: (context, _) {
                if (_store.isAuthenticated) {
                  return GlobalBrandHomeScreen(
                    onSignOut: () {
                      _store.signOut();
                      if (mounted) setState(() {});
                    },
                  );
                }
                return GroundFlowLoginScreen(
                  onLoginSuccess: () {
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
    );
  }
}
