import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:haru_diary/widgets/cloud_card.dart';
import 'package:haru_diary/theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nickCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  File? _image;
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _nickCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<bool> _isNicknameDuplicate(String nickname) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q = await FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isEqualTo: nickname)
        .limit(5)
        .get();
    // 본인 문서 제외
    return q.docs.any((d) => d.id != uid);
  }

  Future<void> _submitProfile() async {
    final nickname = _nickCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    if (nickname.isEmpty || bio.isEmpty) {
      setState(() => _error = '닉네임과 소개는 반드시 입력해야 합니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 닉네임 중복 체크
      if (await _isNicknameDuplicate(nickname)) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = '이미 사용 중인 닉네임입니다.';
        });
        return;
      }

      // 이미지 업로드(선택)
      String? photoUrl;
      if (_image != null) {
        final ref = FirebaseStorage.instance.ref('profile_images/$uid.jpg');
        await ref.putFile(_image!);
        photoUrl = await ref.getDownloadURL();
      }

      // users 컬렉션에 저장 (필드 키 일관화: displayName / bio / photoUrl)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': nickname,
        'bio': bio,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // FirebaseAuth 프로필도 업데이트
      await FirebaseAuth.instance.currentUser!.updateDisplayName(nickname);
      if (photoUrl != null) {
        await FirebaseAuth.instance.currentUser!.updatePhotoURL(photoUrl);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '저장 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              // 아바타 카드
              CloudCard(
                radius: 24,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: cs.surfaceVariant,
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? Icon(Icons.person, size: 50, color: cs.outline)
                            : null,
                      ),
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 닉네임 카드
              CloudCard(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: TextField(
                  controller: _nickCtrl,
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 자기소개 카드
              CloudCard(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '자기소개',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    _error,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),

              const SizedBox(height: 8),

              // 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
