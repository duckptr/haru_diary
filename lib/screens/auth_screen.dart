import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bouncy_async_button.dart';
// import '../widgets/bouncy_button.dart'; // 회원가입 버튼을 OutlinedButton으로 변경하며 제거
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

  static const double _fieldHeight = 104; // 입력 박스 2배 높이 (유지)

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

  void _goHome() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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

  // 공통 입력 박스 (필드 내부 왼쪽 여백 강화, 바깥 패딩은 원래 감각으로 복구)
  Widget _inputBox({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    Widget? suffix,
  }) {
    final cs = Theme.of(context).colorScheme;
    return CloudCard(
      radius: 20,
      // 바깥 패딩: 좌우 12로 복구
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SizedBox(
        height: _fieldHeight,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          // 본문 폰트 17로 미세 다운
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                height: 1.3,
                fontSize: 17,
              ),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            labelText: label,
            // 라벨/힌트 15로 미세 다운
            labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  color: cs.outline,
                ),
            filled: false,
            border: InputBorder.none,
            isDense: true,
            // ✨ 필드 내부 왼쪽 여백 확대(붙어보임 해소의 핵심)
            contentPadding: const EdgeInsets.only(left: 14, right: 0),
            suffixIcon: suffix ?? const SizedBox.shrink(),
            suffixIconConstraints: const BoxConstraints.tightFor(width: 56, height: 56),
          ),
        ),
      ),
    );
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
              _inputBox(
                controller: _emailCtrl,
                label: '이메일',
                hint: 'example@gmail.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 1), // ⬅️ 세로 간격 유지

              // 비밀번호
              _inputBox(
                controller: _pwdCtrl,
                label: '비밀번호',
                hint: '********',
                obscure: _obscurePwd,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  try {
                    await _submit();
                    _goHome();
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    setState(() => _error = e.message ?? '알 수 없는 오류 발생');
                  }
                },
                suffix: IconButton(
                  tooltip: _obscurePwd ? '표시' : '숨기기',
                  icon: Icon(
                    _obscurePwd ? Icons.visibility_off : Icons.visibility,
                    color: cs.outline,
                    size: 28,
                  ),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 56, height: 56),
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

              // 로그인 (주 버튼)
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: BouncyAsyncButton(
                  text: '로그인',
                  onPressed: () async {
                    try {
                      await _submit();
                      return; // 성공 시 onFinished 호출
                    } on FirebaseAuthException catch (e) {
                      setState(() => _error = e.message ?? '알 수 없는 오류 발생');
                      rethrow; // 실패 상태를 버튼에 전달
                    }
                  },
                  onFinished: _goHome,
                ),
              ),
              const SizedBox(height: 8),

              // 회원가입 (보조 버튼) — 테마색 얇은 테두리 & 동일 색 텍스트
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.primary, width: 1),
                    foregroundColor: cs.primary,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: theme.textTheme.labelLarge,
                  ),
                  child: const Text('회원가입'),
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
            ],
          ),
        ),
      ),
    );
  }
}
