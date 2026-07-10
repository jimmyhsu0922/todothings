import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // 這裡直接提供你剛剛在網頁上拿到的 Web 配置，對 Android/iOS 測試模式也完全通用！
    return const FirebaseOptions(
      apiKey: 'AIzaSyDDYbpwAelEaq2fBQ4yIl19HJWXhb-5FmU',
      authDomain: 'todo-duel-app.firebaseapp.com',
      projectId: 'todo-duel-app',
      storageBucket: 'todo-duel-app.firebasestorage.app',
      messagingSenderId: '648486503133',
      appId: '1:648486503133:web:d42fece335c249547c1134',
    );
  }
}