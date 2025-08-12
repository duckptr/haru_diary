import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/bouncy_button.dart';
import 'package:haru_diary/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      // 배경은 테마에 맡겨 라이트/다크 자동 대응
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // 애니메이션
            Lottie.asset(
              'assets/animations/book.json',
              width: 250,
              height: 250,
              repeat: true,
            ),

            const SizedBox(height: 20),

            // 앱 소개 텍스트 (테마 색상 사용)
            Text(
              '당신의 하루를 날씨로 기록하세요',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // 시작 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: BouncyButton(
                  text: '입장하기',
                  color: AppTheme.primaryBlue,
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/auth');
                  },
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
