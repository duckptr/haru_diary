import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:haru_diary/widgets/bouncy_async_button.dart';
import 'package:haru_diary/theme/app_theme.dart';

class EmailVerifiedScreen extends StatelessWidget {
  const EmailVerifiedScreen({super.key});

  Future<void> _fakeDelay() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      // 배경은 테마에 맡김 (라이트/다크 자동 대응)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // 체크 애니메이션
              Lottie.asset(
                'assets/animations/check.json',
                width: 160,
                height: 160,
                repeat: false,
              ),
              const SizedBox(height: 20),

              // 타이틀
              Text(
                '회원가입 완료!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // 서브 텍스트
              Text(
                '오늘부터, 당신의 하루는 이야기가 됩니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // 진행 버튼
              SizedBox(
                width: double.infinity,
                child: BouncyAsyncButton(
                  text: '로그인 진행하기',
                  onPressed: _fakeDelay,
                  onFinished: () {
                    Navigator.pushReplacementNamed(context, '/auth');
                  },
                  color: AppTheme.primaryBlue,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
