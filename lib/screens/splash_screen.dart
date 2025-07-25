import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/bouncy_button.dart'; // ✅ 공용 버튼 위젯 import

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 다크모드 대응
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // 🎞️ Lottie 애니메이션
            Lottie.asset(
              'assets/animations/camping.json',
              width: 250,
              height: 250,
              repeat: true,
            ),

            const SizedBox(height: 20),

            // 📝 앱 소개 텍스트
            const Text(
              '하루의 기분을 날씨로 남기세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // 🎯 부드럽게 튕기는 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: BouncyButton(
                  text: '입장하기',
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
