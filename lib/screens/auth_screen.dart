import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bouncy_async_button.dart';
import '../widgets/bouncy_button.dart'; // ✅ BouncyButton import 필요

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscurePwd = true;
  String _error = '';

  Future<void> _submit() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _pwdCtrl.text.trim(),
    );
  }

  void _handleFinish() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.06;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Center(
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                const Text('이메일', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'example@google.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),
                const Text('비밀번호', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: _pwdCtrl,
                  obscureText: _obscurePwd,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '********',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePwd ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePwd = !_obscurePwd),
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: 비밀번호 찾기
                    },
                    child: const Text(
                      '비밀번호 찾기',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ 로그인 버튼 (그대로 유지)
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: BouncyAsyncButton(
                    text: '로그인',
                    onPressed: () async {
                      try {
                        await _submit();
                        return;
                      } on FirebaseAuthException catch (e) {
                        setState(() =>
                            _error = e.message ?? '알 수 없는 오류 발생');
                        rethrow;
                      }
                    },
                    onFinished: _handleFinish,
                  ),
                ),

                const SizedBox(height: 8),

                // ✅ 회원가입 버튼 (BouncyButton + 회색)
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: BouncyButton(
                    text: '회원가입',
                    color: const Color(0xFF4B5563),
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                  ),
                ),

                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 40),

                // ✅ 구글 로그인 버튼 (BouncyAsyncButton + 회색)
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: BouncyAsyncButton(
                    text: '구글 로그인',
                    color: const Color(0xFF4B5563),
                    onPressed: () async {
                      // TODO: 구글 로그인 처리
                    },
                    onFinished: () {
                      // TODO: 구글 로그인 완료 후 이동
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
