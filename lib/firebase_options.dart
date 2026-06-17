import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('السحابة متاحة حالياً على الويب فقط.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC95TWGzoiVrKCZ1_RnCP7YM86LJEb60Gk',
    authDomain: 'implant-stock-8345d.firebaseapp.com',
    projectId: 'implant-stock-8345d',
    storageBucket: 'implant-stock-8345d.firebasestorage.app',
    messagingSenderId: '561154567507',
    appId: '1:561154567507:web:c233837091be70b75645a6',
    measurementId: 'G-YGYRC4TYDE',
  );
}
