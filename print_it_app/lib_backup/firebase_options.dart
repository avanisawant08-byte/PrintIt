// File generated to provide Web Firebase options
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAqy84RsMk86a6boA-xi5ZNFHbhhLd5Cd8',
    appId: '1:374717568400:web:20b913be55ae68a3354f15',
    messagingSenderId: '374717568400',
    projectId: 'printit-2ba1a',
    authDomain: 'printit-2ba1a.firebaseapp.com',
    storageBucket: 'printit-2ba1a.firebasestorage.app',
    measurementId: 'G-3SQW12SP9E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAgq8rZRBY6LrDO9HPAgpSZyhVptcG0PXk',
    appId: '1:374717568400:android:2cefa6956a994200354f15',
    messagingSenderId: '374717568400',
    projectId: 'printit-2ba1a',
    storageBucket: 'printit-2ba1a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqy84RsMk86a6boA-xi5ZNFHbhhLd5Cd8',
    appId: '1:374717568400:ios:abcdefg',
    messagingSenderId: '374717568400',
    projectId: 'printit-2ba1a',
    storageBucket: 'printit-2ba1a.firebasestorage.app',
    iosBundleId: 'com.example.printItApp',
  );
}
