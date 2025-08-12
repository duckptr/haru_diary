import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'theme/theme_service.dart'; // ← 추가: 테마 저장/로드
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
  await dotenv.load();           // ✅ .env 로딩
  await Firebase.initializeApp(); // ✅ Firebase 초기화

  // 저장된 테마 모드 로드 (없으면 라이트가 기본)
  final initialMode = await ThemeService.load();

  runApp(MyApp(initialMode: initialMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialMode;
  const MyApp({super.key, required this.initialMode});

  // 어디서든 테마 바꾸기 쉽게 제공 (예: MyPageScreen에서 호출)
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _mode = widget.initialMode;

  /// 마이페이지 등에서 호출: 다크/라이트 전환
  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() => _mode = mode);
    await ThemeService.save(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하루 일기',
      debugShowCheckedModeBanner: false,

      // ✅ 기본 라이트 테마 + 다크 테마 제공
      theme: AppTheme.light,   // 기본: 라이트
      darkTheme: AppTheme.dark,
      themeMode: _mode,        // 저장된 값 반영 (라이트/다크)

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
        '/':               (context) => const SplashScreen(),
        '/auth':           (context) => const AuthScreen(),
        '/profile':        (context) => const ProfileSetupScreen(),
        '/home':           (context) => const HomeScreen(),
        '/write':          (context) => const WriteDiaryScreen(),
        '/diary_list':     (context) => const DiaryListScreen(),
        '/mypage':         (context) => const MyPageScreen(),
        '/statistics':     (context) => const StatisticsScreen(),
        '/signup':         (context) => const SignScreen(),
        '/email_verified': (context) => const EmailVerifiedScreen(),
        '/fix_profile':    (context) => const FixProfileScreen(),
        '/ai_chat':        (context) => const AiChatScreen(),
      },
    );
  }
}
