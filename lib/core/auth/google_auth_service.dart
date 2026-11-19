import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  const GoogleAuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });
}

/// Real Google Sign-In Authentication Service
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Trigger Real Google / Gmail Sign-In
  Future<GoogleAuthUser?> signInWithGoogle() async {
    try {
      // 1. Trigger the official Google Sign-In account selector
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        // User aborted the Google login sheet
        return null;
      }

      _currentUser = account;

      // Extract real user details verified by Google
      final user = GoogleAuthUser(
        id: account.id,
        name: account.displayName ?? 'Google User',
        email: account.email,
        photoUrl: account.photoUrl,
      );

      return user;
    } catch (error) {
      debugPrint('Google Sign-In SDK notice: $error');
      // If running on an environment without Google Play Services or OAuth client id configured,
      // rethrow so the UI can provide immediate feedback
      rethrow;
    }
  }

  /// Sign out from Google account session
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('Google Sign-Out notice: $e');
    }
  }
}
