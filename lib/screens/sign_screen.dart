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

  Future<void> _submit() async {
    if (_pwdCtrl.text != _pwdConfirmCtrl.text) {
      setState(() => _error = '비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final greenColor = const Color(0xFF0B872C);
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.07;

    InputDecoration buildInput(String hint, {Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white, // ✅ 흰색으로 고정
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: greenColor),
        ),
        suffixIcon: suffixIcon,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('회원가입'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('성', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: TextField(controller: _lastNameCtrl, decoration: buildInput('성'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _firstNameCtrl, decoration: buildInput('이름'))),
              ],
            ),
            const SizedBox(height: 16),
            const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(controller: _nicknameCtrl, decoration: buildInput('닉네임')),
            const SizedBox(height: 16),
            const Text('이메일', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: buildInput('이메일을 입력하세요.'),
            ),
            const SizedBox(height: 16),
            const Text('비밀번호', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _pwdCtrl,
              obscureText: _obscurePwd,
              decoration: buildInput(
                '********',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('비밀번호 확인', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(controller: _pwdConfirmCtrl, obscureText: _obscurePwd, decoration: buildInput('********')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: BouncyButton(
                text: '이메일 인증하기',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
