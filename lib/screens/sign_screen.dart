import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bouncy_button.dart';

class SignScreen extends StatefulWidget {
  const SignScreen({super.key});

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwdConfirmCtrl = TextEditingController();

  String _error = '';
  bool _isLoading = false;
  bool _obscurePwd = true;

  bool isEmailValid(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool isPasswordValid(String pwd) {
    return pwd.length >= 8;
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    final confirmPwd = _pwdConfirmCtrl.text.trim();

    if (!isEmailValid(email)) {
      setState(() => _error = '이메일 형식을 확인해주세요.');
      return;
    }

    if (!isPasswordValid(pwd)) {
      setState(() => _error = '비밀번호는 8자리 이상이어야 합니다.');
      return;
    }

    if (pwd != confirmPwd) {
      setState(() => _error = '비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pwd,
      );

      await userCred.user!.updateDisplayName(_nicknameCtrl.text.trim());
      await userCred.user!.sendEmailVerification();

      Navigator.pushReplacementNamed(context, '/email_verified');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? '회원가입 실패');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration buildInput(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.07;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('성', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lastNameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInput('성'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _firstNameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: buildInput('이름'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('닉네임', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _nicknameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: buildInput('닉네임'),
            ),
            const SizedBox(height: 16),
            const Text('이메일', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: buildInput('이메일을 입력하세요.'),
            ),
            const SizedBox(height: 16),
            const Text('비밀번호', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _pwdCtrl,
              obscureText: _obscurePwd,
              style: const TextStyle(color: Colors.white),
              decoration: buildInput(
                '********',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('비밀번호 확인', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _pwdConfirmCtrl,
              obscureText: _obscurePwd,
              style: const TextStyle(color: Colors.white),
              decoration: buildInput('********'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: BouncyButton(
                text: '회원가입 완료하기',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
