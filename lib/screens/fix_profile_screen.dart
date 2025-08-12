import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ 추가
import 'package:haru_diary/widgets/cloud_card.dart';
import 'package:haru_diary/theme/app_theme.dart';

class FixProfileScreen extends StatefulWidget {
  const FixProfileScreen({super.key});

  @override
  State<FixProfileScreen> createState() => _FixProfileScreenState();
}

class _FixProfileScreenState extends State<FixProfileScreen> {
  final _nicknameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  File? _selectedImage;
  bool _isCheckingNickname = false;
  String? _nicknameError;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _nicknameCtrl.text = data['displayName'] ?? '';
        _bioCtrl.text = data['bio'] ?? '';
        _photoUrl = data['photoUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _selectedImage = File(image.path));
  }

  Future<String?> _uploadProfileImage(File file) async {
    final uid = _auth.currentUser!.uid;
    final ref = _storage.ref().child('profile_images').child('$uid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<bool> _isNicknameDuplicate(String nickname) async {
    final query = await _firestore
        .collection('users')
        .where('displayName', isEqualTo: nickname)
        .get();

    final currentUid = _auth.currentUser!.uid;
    for (var doc in query.docs) {
      if (doc.id != currentUid) return true;
    }
    return false;
  }

  Future<void> _saveProfile() async {
    final uid = _auth.currentUser!.uid;
    final nickname = _nicknameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    setState(() {
      _nicknameError = null;
      _isCheckingNickname = true;
    });

    if (await _isNicknameDuplicate(nickname)) {
      if (!mounted) return;
      setState(() {
        _nicknameError = '이미 사용 중인 닉네임입니다.';
        _isCheckingNickname = false;
      });
      return;
    }

    String? imageUrl = _photoUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadProfileImage(_selectedImage!);
    }

    await _firestore.collection('users').doc(uid).set({
      'displayName': nickname,
      'photoUrl': imageUrl,
      'bio': bio,
    }, SetOptions(merge: true));

    await _auth.currentUser!.updateDisplayName(nickname);
    await _auth.currentUser!.updatePhotoURL(imageUrl);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/mypage');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아바타 + 카메라 버튼
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
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_photoUrl != null ? NetworkImage(_photoUrl!) : null)
                              as ImageProvider<Object>?,
                      child: _selectedImage == null && _photoUrl == null
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

            // 닉네임 + 중복확인
            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nicknameCtrl,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        border: const OutlineInputBorder(borderSide: BorderSide.none),
                        errorText: _nicknameError,
                      ),
                      onChanged: (_) {
                        if (_nicknameError != null) {
                          setState(() => _nicknameError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: () async {
                        final nickname = _nicknameCtrl.text.trim();
                        if (nickname.isEmpty) return;

                        setState(() => _isCheckingNickname = true);
                        final isDuplicate = await _isNicknameDuplicate(nickname);
                        if (!mounted) return;
                        setState(() {
                          _isCheckingNickname = false;
                          _nicknameError = isDuplicate ? '이미 사용 중인 닉네임입니다.' : null;
                        });

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('닉네임 확인'),
                            content: Text(
                              isDuplicate
                                  ? '이미 사용 중인 닉네임입니다.'
                                  : '사용 가능한 닉네임입니다.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCheckingNickname
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('중복 확인', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 자기소개
            CloudCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _bioCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '자기소개',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
