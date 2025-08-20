import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haru_diary/utils/validators.dart';

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

  static const String _colUsers = 'users';
  static const String _colUsernames = 'usernames';

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

  bool isEmailValid(String email) =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);

  bool isPasswordValid(String pwd) => pwd.length >= 8;

  String _prettyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '이메일 형식을 확인해주세요.';
      case 'operation-not-allowed':
        return '이메일/비밀번호 가입이 비활성화되어 있습니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 8자 이상으로 설정해주세요.';
      default:
        return e.message ?? '회원가입 실패';
    }
  }

  Future<bool> _emailExists(String email) async {
    final methods =
        await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

  Future<bool> _nicknameDocExists(String nicknameLower) async {
    final snap = await FirebaseFirestore.instance
        .collection(_colUsernames)
        .doc(nicknameLower)
        .get();
    return snap.exists;
  }

  Future<void> _reserveNicknameOrThrow({
    required String nicknameLower,
    required String uid,
  }) async {
    final col = FirebaseFirestore.instance.collection(_colUsernames);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final ref = col.doc(nicknameLower);
      final doc = await tx.get(ref);
      if (doc.exists) {
        throw Exception('nickname_taken');
      }
      tx.set(ref, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _createOrMergeUserProfile({
    required User user,
    required String email,
    required String displayName,
    required String first,
    required String last,
    required String nickname,
  }) async {
    final users = FirebaseFirestore.instance.collection(_colUsers);
    await users.doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'displayName': displayName,
      'firstName': first,
      'lastName': last,
      'nickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    final confirmPwd = _pwdConfirmCtrl.text.trim();
    final nicknameRaw = _nicknameCtrl.text.trim();
    final nicknameLower = nicknameRaw.toLowerCase();
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();

    if (nicknameRaw.isEmpty) {
      setState(() => _error = '닉네임을 입력해주세요.');
      return;
    }
    if (!Validators.isNicknameValid(nicknameRaw)) {
      setState(() => _error = '닉네임 형식을 확인해주세요. (한글/영문/숫자/_ 2~20자)');
      return;
    }
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
      if (await _emailExists(email)) {
        setState(() {
          _error = '이미 사용 중인 이메일입니다.';
          _isLoading = false;
        });
        return;
      }
      if (await _nicknameDocExists(nicknameLower)) {
        setState(() {
          _error = '이미 사용 중인 닉네임입니다.';
          _isLoading = false;
        });
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pwd,
      );
      final user = cred.user;
      if (user == null) {
        setState(() {
          _error = '회원가입에 실패했습니다. 다시 시도해주세요.';
          _isLoading = false;
        });
        return;
      }

      await user.updateDisplayName(nicknameRaw);

      try {
        await _reserveNicknameOrThrow(
          nicknameLower: nicknameLower,
          uid: user.uid,
        );
      } catch (e) {
        try {
          await user.delete();
        } catch (_) {}
        setState(() {
          _error = '이미 사용 중인 닉네임입니다.';
          _isLoading = false;
        });
        return;
      }

      await _createOrMergeUserProfile(
        user: user,
        email: email,
        displayName: nicknameRaw,
        first: first,
        last: last,
        nickname: nicknameRaw,
      );

      await user.sendEmailVerification();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/email_verified',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _prettyAuthError(e);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '알 수 없는 오류가 발생했습니다.';
        _isLoading = false;
      });
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

    // 뒤로가기 가능 여부
    final canPop = Navigator.canPop(context);

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

            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _nicknameCtrl,
                textInputAction: TextInputAction.next,
                decoration: _inCardInput(label: '닉네임 *', hint: '표시될 이름(필수)'),
              ),
            ),
            const SizedBox(height: 12),

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

            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _pwdConfirmCtrl,
                obscureText: _obscurePwd,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_isLoading) return;
                  _submit();
                },
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

            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: BouncyButton(
                text: '회원가입 완료하기',
                isLoading: _isLoading,
                color: AppTheme.primaryBlue,
                onPressed: () {
                  if (_isLoading) return;
                  _submit();
                },
              ),
            ),

            const SizedBox(height: 12),

            // 여기: 삼항으로 항상 위젯을 반환(낮은 Dart 버전 호환)
            (!canPop)
                ? Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/auth',
                          (route) => false,
                        );
                      },
                      child: const Text('이미 계정이 있으신가요? 로그인'),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
