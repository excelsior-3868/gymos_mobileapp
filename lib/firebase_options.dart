import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration generated from GoogleService-Info.plist & google-services.json (fitmaxim-72a3d).
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatformOrNull {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return null;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYFhjmbKW_V98Oj5HiIoKHB1EGfbuR-i0',
    appId: '1:420389756295:android:24a1d6ad9ffaeb92d50722',
    messagingSenderId: '420389756295',
    projectId: 'fitmaxim-72a3d',
    storageBucket: 'fitmaxim-72a3d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBKodnGcpkAN6FjEvHDMBt475XM9lX6BHw',
    appId: '1:420389756295:ios:253686e3716cf4d1d50722',
    messagingSenderId: '420389756295',
    projectId: 'fitmaxim-72a3d',
    storageBucket: 'fitmaxim-72a3d.firebasestorage.app',
    iosBundleId: 'com.gymos.member.gymos-mobile',
  );
}
