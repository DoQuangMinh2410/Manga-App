// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/manga_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/chapter_provider.dart';
import 'services/database_service.dart';
import 'services/preferences_service.dart';
import 'services/firebase_service.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Khởi tạo Firebase
  // ⚠️ Cần cấu hình firebase_options.dart trước khi chạy
  // Xem hướng dẫn trong lib/firebase_options.dart
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase chưa cấu hình — app vẫn chạy với SQLite offline
    debugPrint('⚠️ Firebase chưa cấu hình: $e');
    debugPrint('App sẽ chạy ở chế độ offline (SQLite only)');
  }

  runApp(const MangaReaderApp());
}

class MangaReaderApp extends StatelessWidget {
  const MangaReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final prefsService = PreferencesService();
    final firebaseService = FirebaseService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefsService),
        ),
        ChangeNotifierProvider(
          create: (_) => MangaProvider(dbService, prefsService),
        ),
        ChangeNotifierProvider(
          create: (_) => app_auth.AuthProvider(firebaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChapterProvider(firebaseService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MangaVerse',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler
                        .scale(1.0)
                        .clamp(0.85, 1.15),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
