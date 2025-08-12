import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/bouncy_button.dart';
import 'package:haru_diary/widgets/cloud_card.dart';
import 'package:haru_diary/theme/app_theme.dart';

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

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _pwdConfirmCtrl.dispose();
    super.dispose();
  }

  bool isEmailValid(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
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

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pwd,
      );
      await cred.user!.updateDisplayName(_nicknameCtrl.text.trim());
      await cred.user!.sendEmailVerification();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/email_verified');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? '회원가입 실패');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inCardInput({
    String? label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(borderSide: BorderSide.none),
    ).copyWith(suffixIcon: suffixIcon);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.07;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 성/이름
            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lastNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _inCardInput(label: '성', hint: '홍'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _firstNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _inCardInput(label: '이름', hint: '길동'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 닉네임
            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _nicknameCtrl,
                textInputAction: TextInputAction.next,
                decoration: _inCardInput(label: '닉네임', hint: '표시될 이름'),
              ),
            ),
            const SizedBox(height: 12),

            // 이메일
            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _inCardInput(label: '이메일', hint: 'example@google.com'),
              ),
            ),
            const SizedBox(height: 12),

            // 비밀번호
            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _pwdCtrl,
                obscureText: _obscurePwd,
                textInputAction: TextInputAction.next,
                decoration: _inCardInput(
                  label: '비밀번호',
                  hint: '8자리 이상',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                    tooltip: _obscurePwd ? '표시' : '숨기기',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 비밀번호 확인
            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _pwdConfirmCtrl,
                obscureText: _obscurePwd,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: _inCardInput(label: '비밀번호 확인', hint: '다시 입력'),
              ),
            ),

            const SizedBox(height: 20),

            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error,
                  style: TextStyle(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ),

            // 회원가입 버튼
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: BouncyButton(
                text: '회원가입 완료하기',
                isLoading: _isLoading,
                color: AppTheme.primaryBlue,
                onPressed: _submit,
              ),
            ),

            const SizedBox(height: 12),

            // 이미 계정이 있나요?
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                child: const Text('이미 계정이 있으신가요? 로그인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
