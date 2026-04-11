// ignore_for_file: type=lint
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (Platform.isAndroid) return android;
    if (Platform.isIOS) return ios;
    if (Platform.isMacOS) return macos;
    if (Platform.isWindows) return windows;
    if (Platform.isLinux) return linux;
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDOBr1GoAtgXmaJHm3tEAvxJIfQCaYZFGo',
    appId: '1:931475441186:web:867e350107c698aeb3ec7b',
    messagingSenderId: '931475441186',
    projectId: 'chatix-a7228',
    authDomain: 'chatix-a7228.firebaseapp.com',
    storageBucket: 'chatix-a7228.firebasestorage.app',
    measurementId: 'G-P3K1WGWE9B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3J371D1d7Pufm25nQYpjsGyArvk_pmiI',
    appId: '1:931475441186:android:5abfbb20b6337e5cb3ec7b',
    messagingSenderId: '931475441186',
    projectId: 'chatix-a7228',
    storageBucket: 'chatix-a7228.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDOBr1GoAtgXmaJHm3tEAvxJIfQCaYZFGo',
    appId: '1:931475441186:web:fd2c9741a1453c00b3ec7b',
    messagingSenderId: '931475441186',
    projectId: 'chatix-a7228',
    authDomain: 'chatix-a7228.firebaseapp.com',
    storageBucket: 'chatix-a7228.firebasestorage.app',
    measurementId: 'G-61ZB1BF8FH',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB2-dRSpVP_xgE__dlmXCDhzKovNth05Yg',
    appId: '1:931475441186:ios:d3348f167ebf40d2b3ec7b',
    messagingSenderId: '931475441186',
    projectId: 'chatix-a7228',
    storageBucket: 'chatix-a7228.firebasestorage.app',
    androidClientId: '931475441186-h22j6aosih44ubv1ht589mfb3mnsfjnb.apps.googleusercontent.com',
    iosClientId: '931475441186-shvvgdltmq7m6ijv2b61bnm7q9a7ejd3.apps.googleusercontent.com',
    iosBundleId: 'com.dualproj.rizz',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2-dRSpVP_xgE__dlmXCDhzKovNth05Yg',
    appId: '1:931475441186:ios:d3348f167ebf40d2b3ec7b',
    messagingSenderId: '931475441186',
    projectId: 'chatix-a7228',
    storageBucket: 'chatix-a7228.firebasestorage.app',
    androidClientId: '931475441186-h22j6aosih44ubv1ht589mfb3mnsfjnb.apps.googleusercontent.com',
    iosClientId: '931475441186-shvvgdltmq7m6ijv2b61bnm7q9a7ejd3.apps.googleusercontent.com',
    iosBundleId: 'com.dualproj.rizz',
  );

  // Для Linux используем Android-конфигурацию (она совместима с десктопом)
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyA3J371D1d7Pufm25nQYpjsGyArvk_pmiI',
    appId: '1:931475441186:android:5abfbb20b6337e5cb3ec7b',
    messagingSenderId: '931475441186',
    projectId: 'chatix-a7228',
    storageBucket: 'chatix-a7228.firebasestorage.app',
  );
}