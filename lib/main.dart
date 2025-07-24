import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';               // Firebase core 임포트
import 'package:flutter_localizations/flutter_localizations.dart'; // 로컬라이제이션

import 'theme/app_theme.dart';                                   // AppTheme 임포트
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/write_diary_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/diary_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화 준비
  await Firebase.initializeApp();            // Firebase 초기화

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하루 일기',
      debugShowCheckedModeBanner: false,

      // ▶️ 공통 테마 연결
      theme: AppTheme.light,

      // 🌐 로컬라이제이션 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', ''), // 한국어
        Locale('en', ''), // 영어
      ],

      initialRoute: '/',
      routes: {
        '/':       (context) => const SplashScreen(),
        '/auth':   (context) => const AuthScreen(),
        '/profile':(context) => const ProfileSetupScreen(),
        '/home':   (context) => const HomeScreen(),
        '/write':  (context) => const WriteDiaryScreen(),
        '/diary_list': (context) => const DiaryListScreen(),
        '/mypage': (context) => const MyPageScreen(),
      },
    );
  }
}
