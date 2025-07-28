import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:haru_diary/widgets/bouncy_async_button.dart';

class EmailVerifiedScreen extends StatelessWidget {
  const EmailVerifiedScreen({super.key});

  Future<void> _fakeDelay() async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Lottie check animation
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
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // BouncyAsyncButton 사용
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
                    color: Colors.black,
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
