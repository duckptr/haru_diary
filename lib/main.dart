import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/write_diary_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/diary_list_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/sign_screen.dart';
import 'screens/email_verified_screen.dart';
import 'screens/fix_profile_screen.dart';
import 'screens/ai_chat_screen.dart'; // ✅ AI 채팅 화면 추가

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // ✅ .env 로딩
  await Firebase.initializeApp(); // ✅ Firebase 초기화

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하루 일기',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', ''),
        Locale('en', ''),
      ],
      initialRoute: '/',
      routes: {
        '/':             (context) => const SplashScreen(),
        '/auth':         (context) => const AuthScreen(),
        '/profile':      (context) => const ProfileSetupScreen(),
        '/home':         (context) => const HomeScreen(),
        '/write':        (context) => const WriteDiaryScreen(),
        '/diary_list':   (context) => const DiaryListScreen(),
        '/mypage':       (context) => const MyPageScreen(),
        '/statistics':   (context) => const StatisticsScreen(),
        '/signup':       (context) => const SignScreen(),
        '/email_verified': (context) => const EmailVerifiedScreen(),
        '/fix_profile':  (context) => const FixProfileScreen(),
        '/ai_chat':      (context) => const AiChatScreen(), 
      },
    );
  }
}
