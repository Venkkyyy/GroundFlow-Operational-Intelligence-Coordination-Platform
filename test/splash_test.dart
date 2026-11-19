import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ground_flow/main.dart';
import 'package:ground_flow/core/state/ground_flow_realtime_store.dart';
import 'package:ground_flow/features/splash/groundflow_splash_screen.dart';
import 'package:ground_flow/features/auth/groundflow_login_screen.dart';
import 'package:ground_flow/features/home/global_brand_home_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'gf_auth': false});
    final store = GroundFlowRealtimeStore();
    await store.signOut();
  });

  testWidgets(
      'Splash Screen displays animated logo and redirects to Login when not logged in',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: GroundFlowApp(),
      ),
    );

    // Initial frame shows Splash Screen with Animated Logo & App Title
    expect(find.byType(GroundFlowSplashScreen), findsOneWidget);
    expect(find.byIcon(Icons.hub_rounded), findsOneWidget);
    expect(find.text('GroundFlow'), findsWidgets);

    // Advance time until splash animation completes
    await tester.pumpAndSettle();

    // Must redirect to GroundFlowLoginScreen
    expect(find.byType(GroundFlowLoginScreen), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets(
      'Splash Screen redirects directly to GlobalBrandHomeScreen when user is already logged in',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final store = GroundFlowRealtimeStore();
    await store.signInWithGoogle(
      name: 'Super Creator',
      email: 'creator@groundflow.app',
      role: AppRole.departmentHead,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: GroundFlowApp(),
      ),
    );

    // Advance time until splash animation completes
    await tester.pumpAndSettle();

    // Must redirect directly to GlobalBrandHomeScreen
    expect(find.byType(GlobalBrandHomeScreen), findsOneWidget);
    expect(find.textContaining('Super Creator'), findsWidgets);
  });
}
