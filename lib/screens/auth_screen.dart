import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bouncy_async_button.dart';
import '../widgets/bouncy_button.dart';
import 'package:haru_diary/widgets/cloud_card.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _pwdCtrl.text.trim(),
    );
  }

  void _handleFinish() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('비밀번호 재설정 메일 전송'),
          content: Text('입력한 이메일로 재설정 링크를 보냈어요.\n($email)'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '메일 전송 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = screenHeight * 0.06;

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이메일
              CloudCard(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@google.com',
                    // 🔧 전역 filled(true) 무시해서 카드 배경만 보이게
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
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
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '********',
                    filled: false,                // 🔧
                    border: InputBorder.none,     // 🔧
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: IconButton(
                      tooltip: _obscurePwd ? '표시' : '숨기기',
                      icon: Icon(
                        _obscurePwd ? Icons.visibility_off : Icons.visibility,
                        color: cs.outline,        // 🔧 라이트 모드에서 회색으로
                      ),
                      onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                    ),
                  ),
                ),
              ),

              // 비밀번호 찾기
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text('비밀번호 찾기'),
                ),
              ),
              const SizedBox(height: 8),

              // 로그인 (주 버튼: 파랑 유지)
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
                      setState(() => _error = e.message ?? '알 수 없는 오류 발생');
                      rethrow; // BouncyAsyncButton 진행 상태에 반영되도록
                    }
                  },
                  onFinished: _handleFinish,
                ),
              ),
              const SizedBox(height: 8),

              // 회원가입 (보조 버튼: 밝은 배경 + 어두운 텍스트)
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: BouncyButton(
                  text: '회원가입',
                  color: cs.surfaceVariant, // 밝은 회색 배경
                  // ⬇⬇ BouncyButton이 textStyle 지원하면 사용, 없으면 위젯에 textStyle만 추가해줘!
                  textStyle: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface),
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                ),
              ),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error,
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // 구글 로그인 (보조 버튼 동일 톤)
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: BouncyAsyncButton(
                  text: '구글 로그인',
                  color: cs.surfaceVariant,
                  textStyle: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface),
                  onPressed: () async {
                    // TODO: 구글 로그인 처리
                  },
                  onFinished: () {
                    // TODO: 구글 로그인 완료 후 이동
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
