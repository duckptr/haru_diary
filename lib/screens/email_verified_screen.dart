import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/bouncy_async_button.dart'; // ✅ 변경된 버튼 임포트

class EmailVerifiedScreen extends StatelessWidget {
  const EmailVerifiedScreen({super.key});

  Future<void> _fakeDelay() async {
    // 실제 로그인 연결 전에 약간의 대기 시간 (예: 서버 통신)
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B872C),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // ✅ Lottie 애니메이션
            Lottie.asset(
              'assets/animations/check.json',
              width: 160,
              height: 160,
              repeat: false,
            ),

            const SizedBox(height: 20),
            const Text(
              '회원가입 완료!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '오늘부터, 당신의 하루는 이야기가 됩니다.',
              style: TextStyle(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),

            // ✅ BouncyAsyncButton 적용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                child: BouncyAsyncButton(
                  text: '로그인 진행하기',
                  onPressed: _fakeDelay,
                  onFinished: () {
                    Navigator.pushReplacementNamed(context, '/auth');
                  },
                  color: Colors.white,
                  textStyle: const TextStyle(
                    color: Color(0xFF0B872C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
