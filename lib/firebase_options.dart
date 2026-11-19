import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for GroundFlow Firebase operations.
/// Configured for Firebase Project: groundflow-acca3
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBROPqX0xipkd_3BFOUbpkVHPJOFAjhMCw',
    appId: '1:60616715172:web:05eba9a9630c33cb906f31',
    messagingSenderId: '60616715172',
    projectId: 'groundflow-acca3',
    authDomain: 'groundflow-acca3.firebaseapp.com',
    storageBucket: 'groundflow-acca3.firebasestorage.app',
    measurementId: 'G-XLD3CEH6N0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsShzNw66MPiVM46OKV2t09ONgEVngnq0',
    appId: '1:60616715172:android:432feaa314f63555906f31',
    messagingSenderId: '60616715172',
    projectId: 'groundflow-acca3',
    storageBucket: 'groundflow-acca3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCNSgOh5MFEcm_9WA57Mo8dF_NDh0ctzuM',
    appId: '1:60616715172:ios:0b2bbf489abdebcd906f31',
    messagingSenderId: '60616715172',
    projectId: 'groundflow-acca3',
    storageBucket: 'groundflow-acca3.firebasestorage.app',
    iosBundleId: 'com.venky.GroundFlow',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBROPqX0xipkd_3BFOUbpkVHPJOFAjhMCw',
    appId: '1:60616715172:web:05eba9a9630c33cb906f31',
    messagingSenderId: '60616715172',
    projectId: 'groundflow-acca3',
    authDomain: 'groundflow-acca3.firebaseapp.com',
    storageBucket: 'groundflow-acca3.firebasestorage.app',
    measurementId: 'G-XLD3CEH6N0',
  );
}
