import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Project  : tuan-27904
/// Package  : com.sky_cinema.sky_cinema
/// SHA-1    : aa310f783148f4e0f6357d0a9223496fe0615815
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web / OAuth web client (type 3)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7vyy19ll8t0hFOzWve5qXlflbL97ehpw',
    appId: '1:455475441924:android:97ac0d1c114313e7c0a051',
    messagingSenderId: '455475441924',
    projectId: 'tuan-27904',
    authDomain: 'tuan-27904.firebaseapp.com',
    storageBucket: 'tuan-27904.firebasestorage.app',
  );

  // Android – com.sky_cinema.sky_cinema
  // Android OAuth client ID (type 1): 455475441924-96ql5mfn3gubv0asv35ns2ap4s8jh7kc
  // Web OAuth client ID   (type 3): 455475441924-n2lkna08fkg8erdqf4fkfspmrtr6e2th
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7vyy19ll8t0hFOzWve5qXlflbL97ehpw',
    appId: '1:455475441924:android:97ac0d1c114313e7c0a051',
    messagingSenderId: '455475441924',
    projectId: 'tuan-27904',
    storageBucket: 'tuan-27904.firebasestorage.app',
  );

  // iOS – chưa cấu hình
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7vyy19ll8t0hFOzWve5qXlflbL97ehpw',
    appId: '1:455475441924:ios:placeholder',
    messagingSenderId: '455475441924',
    projectId: 'tuan-27904',
    storageBucket: 'tuan-27904.firebasestorage.app',
    iosBundleId: 'com.sky_cinema.skyCinema',
  );

  // macOS – chưa cấu hình
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA7vyy19ll8t0hFOzWve5qXlflbL97ehpw',
    appId: '1:455475441924:ios:placeholder',
    messagingSenderId: '455475441924',
    projectId: 'tuan-27904',
    storageBucket: 'tuan-27904.firebasestorage.app',
    iosBundleId: 'com.sky_cinema.skyCinema',
  );
}
