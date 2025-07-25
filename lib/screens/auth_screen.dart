import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bouncy_async_button.dart'; // ✅ 수정된 파일명 주의

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
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
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _pwdCtrl,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: BouncyAsyncButton(
                text: '로그인',
                onPressed: () async {
                  try {
                    await _submit();
                    return;
                  } on FirebaseAuthException catch (e) {
                    setState(() => _error = e.message ?? '알 수 없는 오류');
                    rethrow;
                  }
                },
                onFinished: _handleFinish,
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text('회원가입'),
            ),

            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
