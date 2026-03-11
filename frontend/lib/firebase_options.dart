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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBhj-lLXpwLeoXAb46Q4xfx2NP8kTX3SjI',
    appId: '1:659845068895:web:23e8fbf9af5cef43fcc3ea',
    messagingSenderId: '659845068895',
    projectId: 'atahbracah',
    authDomain: 'atahbracah.firebaseapp.com',
    storageBucket: 'atahbracah.firebasestorage.app',
    measurementId: 'G-S00VM7160T',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhj-lLXpwLeoXAb46Q4xfx2NP8kTX3SjI',
    appId: '1:659845068895:android:your-android-app-id',
    messagingSenderId: '659845068895',
    projectId: 'atahbracah',
    storageBucket: 'atahbracah.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhj-lLXpwLeoXAb46Q4xfx2NP8kTX3SjI',
    appId: '1:659845068895:ios:your-ios-app-id',
    messagingSenderId: '659845068895',
    projectId: 'atahbracah',
    storageBucket: 'atahbracah.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBhj-lLXpwLeoXAb46Q4xfx2NP8kTX3SjI',
    appId: '1:659845068895:macos:your-macos-app-id',
    messagingSenderId: '659845068895',
    projectId: 'atahbracah',
    storageBucket: 'atahbracah.firebasestorage.app',
  );
}
