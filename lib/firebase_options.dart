// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBAUEi1To4EzjPvteogcz-mH7IYA9C3c78',
    appId: '1:946178078121:web:5c369de4e9556ac0ccc0b8',
    messagingSenderId: '946178078121',
    projectId: 'managertimemobile',
    authDomain: 'managertimemobile.firebaseapp.com',
    storageBucket: 'managertimemobile.firebasestorage.app',
    measurementId: 'G-FXVW8E2V3Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBI22BBMI9qZegwFC_zOERHZM40Jzpx-nM',
    appId: '1:946178078121:android:ecba0df98acc1c8cccc0b8',
    messagingSenderId: '946178078121',
    projectId: 'managertimemobile',
    storageBucket: 'managertimemobile.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCixM2rU_xbZ07j8VDRWvdu_PEwyXqqdWE',
    appId: '1:946178078121:ios:4ada3a45d0ade49accc0b8',
    messagingSenderId: '946178078121',
    projectId: 'managertimemobile',
    storageBucket: 'managertimemobile.firebasestorage.app',
    iosBundleId: 'com.example.managertime',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCixM2rU_xbZ07j8VDRWvdu_PEwyXqqdWE',
    appId: '1:946178078121:ios:4ada3a45d0ade49accc0b8',
    messagingSenderId: '946178078121',
    projectId: 'managertimemobile',
    storageBucket: 'managertimemobile.firebasestorage.app',
    iosBundleId: 'com.example.managertime',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBAUEi1To4EzjPvteogcz-mH7IYA9C3c78',
    appId: '1:946178078121:web:340a7921285ff6a5ccc0b8',
    messagingSenderId: '946178078121',
    projectId: 'managertimemobile',
    authDomain: 'managertimemobile.firebaseapp.com',
    storageBucket: 'managertimemobile.firebasestorage.app',
    measurementId: 'G-404XSLCEXW',
  );
}
