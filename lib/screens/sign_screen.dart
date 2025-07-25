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
    final email = _emailCtrl.text.trim();
    final password = _pwdCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();

    if (_pwdCtrl.text != _pwdConfirmCtrl.text) {
      setState(() => _error = '비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCred.user!.updateDisplayName(nickname);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: '성'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(labelText: '이름'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nicknameCtrl,
                decoration: const InputDecoration(labelText: '닉네임'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: '이메일을 입력하세요.',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwdCtrl,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePwd ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                  ),
                ),
                obscureText: _obscurePwd,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwdConfirmCtrl,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                obscureText: _obscurePwd,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: BouncyButton(
                  onPressed: _submit,
                  text: '회원가입',
                  isLoading: _isLoading,
                ),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
