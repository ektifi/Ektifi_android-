// File generated using FlutterFire CLI.
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
    apiKey: 'AIzaSyDqnPLe5zvj5zn3PZfW2gP1xYqSiPkhtb4',
    appId: '1:869939140864:web:be3dce8b06bcb4895c3be5',
    messagingSenderId: '869939140864',
    projectId: 'ektifichat',
    authDomain: 'ektifichat.firebaseapp.com',
    storageBucket: 'ektifichat.firebasestorage.app',
    measurementId: 'G-52Z7KGC86Y', // Optional: For Firebase Analytics
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY', // Get this from Firebase Console after adding Android app
    appId: 'YOUR_ANDROID_APP_ID', // Get this from Firebase Console after adding Android app
    messagingSenderId: '869939140864',
    projectId: 'ektifichat',
    storageBucket: 'ektifichat.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY', // Get this from Firebase Console after adding iOS app
    appId: 'YOUR_IOS_APP_ID', // Get this from Firebase Console after adding iOS app
    messagingSenderId: '869939140864',
    projectId: 'ektifichat',
    storageBucket: 'ektifichat.appspot.com',
    iosBundleId: 'com.example.ektifi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY', // Get this from Firebase Console after adding macOS app
    appId: 'YOUR_MACOS_APP_ID', // Get this from Firebase Console after adding macOS app
    messagingSenderId: '869939140864',
    projectId: 'ektifichat',
    storageBucket: 'ektifichat.appspot.com',
    iosBundleId: 'com.example.ektifi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY', // Get this from Firebase Console after adding Windows app
    appId: 'YOUR_WINDOWS_APP_ID', // Get this from Firebase Console after adding Windows app
    messagingSenderId: '869939140864',
    projectId: 'ektifichat',
    storageBucket: 'ektifichat.appspot.com',
  );
}
