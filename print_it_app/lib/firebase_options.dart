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
    apiKey: 'AIzaSyA3dZxTULY5uqpnThZ7HO2QNe-7_K2E9mE',
    appId: '1:322993568107:web:3de473e5fdeb70ea4db42e',
    messagingSenderId: '322993568107',
    projectId: 'printit-4d823',
    authDomain: 'printit-4d823.firebaseapp.com',
    storageBucket: 'printit-4d823.firebasestorage.app',
    measurementId: 'G-EVT9THSQM2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8F9AUrYaZglIxqNE4fPoDmPllZgkxsA4',
    appId: '1:322993568107:android:bc7b7652714c66bd4db42e',
    messagingSenderId: '322993568107',
    projectId: 'printit-4d823',
    storageBucket: 'printit-4d823.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArvYKchxmD4-cGjl4l2bQOCto2461dpJs',
    appId: '1:322993568107:ios:d14e3cc0127b719f4db42e',
    messagingSenderId: '322993568107',
    projectId: 'printit-4d823',
    storageBucket: 'printit-4d823.firebasestorage.app',
    iosClientId: '322993568107-cevuivprc3ghgak773odrctav0k54m4t.apps.googleusercontent.com',
    iosBundleId: 'com.example.printItApp',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyArvYKchxmD4-cGjl4l2bQOCto2461dpJs',
    appId: '1:322993568107:ios:d14e3cc0127b719f4db42e',
    messagingSenderId: '322993568107',
    projectId: 'printit-4d823',
    storageBucket: 'printit-4d823.firebasestorage.app',
    iosClientId: '322993568107-cevuivprc3ghgak773odrctav0k54m4t.apps.googleusercontent.com',
    iosBundleId: 'com.example.printItApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA3dZxTULY5uqpnThZ7HO2QNe-7_K2E9mE',
    appId: '1:322993568107:web:51c8d9fb32e0ae1a4db42e',
    messagingSenderId: '322993568107',
    projectId: 'printit-4d823',
    authDomain: 'printit-4d823.firebaseapp.com',
    storageBucket: 'printit-4d823.firebasestorage.app',
    measurementId: 'G-XTXYV8G2KM',
  );
}
