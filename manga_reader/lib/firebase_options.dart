// lib/firebase_options.dart
//
// ════════════════════════════════════════════════════════════════════════════
//  ⚠️  HƯỚNG DẪN CẤU HÌNH FIREBASE
// ════════════════════════════════════════════════════════════════════════════
//
//  Bước 1: Cài FlutterFire CLI
//    dart pub global activate flutterfire_cli
//
//  Bước 2: Đăng nhập Firebase
//    firebase login
//
//  Bước 3: Chạy lệnh cấu hình (trong thư mục project)
//    flutterfire configure --project=quangminh
//
//  Lệnh trên sẽ TỰ ĐỘNG tạo lại file này với đúng giá trị
//  từ project Firebase "quangminh" của bạn.
//
//  ── HOẶC thay thủ công ──────────────────────────────────────────────────
//  Vào Firebase Console → Project settings → Your apps
//  Copy các giá trị và thay vào bên dưới:
// ════════════════════════════════════════════════════════════════════════════

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions chưa được cấu hình cho platform này. '
          'Chạy: flutterfire configure --project=quangminh',
        );
    }
  }

  // ── Android ─────────────────────────────────────────────────────────────
  // Lấy từ: Firebase Console → Project Settings → android app → google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',              // ← Thay giá trị này
    appId: 'YOUR_ANDROID_APP_ID',                // ← Thay giá trị này
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID', // ← Thay giá trị này
    projectId: 'quangminh',                       // ← Project ID của bạn
    storageBucket: 'quangminh.appspot.com',       // ← Thay nếu khác
  );

  // ── iOS ─────────────────────────────────────────────────────────────────
  // Lấy từ: Firebase Console → Project Settings → ios app → GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',                  // ← Thay giá trị này
    appId: 'YOUR_IOS_APP_ID',                    // ← Thay giá trị này
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID', // ← Thay giá trị này
    projectId: 'quangminh',
    storageBucket: 'quangminh.appspot.com',
    iosBundleId: 'com.example.mangaReader',       // ← Bundle ID iOS
  );

  // ── Web ─────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'quangminh',
    storageBucket: 'quangminh.appspot.com',
    authDomain: 'quangminh.firebaseapp.com',
  );
}
