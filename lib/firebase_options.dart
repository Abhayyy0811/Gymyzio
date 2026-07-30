// File generated manually based on android/app/google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC71dJaLSxwNDu8wMccJGSi7OPu8v5_mHo',
    appId: '1:991712237098:web:placeholder',
    messagingSenderId: '991712237098',
    projectId: 'gysmysio',
    storageBucket: 'gysmysio.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC71dJaLSxwNDu8wMccJGSi7OPu8v5_mHo',
    appId: '1:991712237098:android:c3e89caea6688817a45553',
    messagingSenderId: '991712237098',
    projectId: 'gysmysio',
    storageBucket: 'gysmysio.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC71dJaLSxwNDu8wMccJGSi7OPu8v5_mHo',
    appId: '1:991712237098:ios:placeholder',
    messagingSenderId: '991712237098',
    projectId: 'gysmysio',
    storageBucket: 'gysmysio.firebasestorage.app',
    iosBundleId: 'com.gymyzio.gymyzio',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC71dJaLSxwNDu8wMccJGSi7OPu8v5_mHo',
    appId: '1:991712237098:ios:placeholder',
    messagingSenderId: '991712237098',
    projectId: 'gysmysio',
    storageBucket: 'gysmysio.firebasestorage.app',
    iosBundleId: 'com.gymyzio.gymyzio',
  );
}
