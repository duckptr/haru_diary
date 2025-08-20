import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ 추가: 공용 유효성 (한글/영문/숫자/_ 2~20자)
import 'package:haru_diary/utils/validators.dart';

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
  String? _photoUrl;

  bool _isCheckingNickname = false;
  String? _nicknameError;
  bool _saving = false;

  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  static const String _colUsers = 'users';
  static const String _colUsernames = 'usernames';

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
    final doc = await _fs.collection(_colUsers).doc(uid).get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        // 표시용 닉네임: nickname 우선, 없으면 displayName
        _nicknameCtrl.text = (data['nickname'] ?? data['displayName'] ?? '').toString();
        _bioCtrl.text = (data['bio'] ?? '').toString();
        _photoUrl = data['photoUrl'] as String?;
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

  /// usernames 컬렉션 기준 중복 체크:
  /// - 문서가 없으면 사용 가능
  /// - 문서가 있고 소유자(uid)가 나면 사용 가능
  /// - 그 외는 사용 불가(중복)
  Future<bool> _isNicknameTaken(String nickname) async {
    final id = nickname.trim().toLowerCase();
    if (id.isEmpty) return true;
    final snap = await _fs.collection(_colUsernames).doc(id).get();
    if (!snap.exists) return false;
    final owner = (snap.data()?['uid'] as String?) ?? '';
    return owner != _auth.currentUser!.uid;
  }

  Future<void> _saveProfile() async {
    if (_saving) return;

    final uid = _auth.currentUser!.uid;
    final newNickRaw = _nicknameCtrl.text.trim();
    final newNickId = newNickRaw.toLowerCase();
    final bio = _bioCtrl.text.trim();

    // 0) 로컬 유효성
    if (!Validators.isNicknameValid(newNickRaw)) {
      setState(() => _nicknameError = '닉네임 형식을 확인해주세요. (한글/영문/숫자/_ 2~20자)');
      return;
    }

    setState(() {
      _nicknameError = null;
      _isCheckingNickname = true;
      _saving = true;
    });

    // 1) 빠른 가용성 체크(UX): 최종 보장은 아래 트랜잭션
    if (await _isNicknameTaken(newNickRaw)) {
      if (!mounted) return;
      setState(() {
        _nicknameError = '이미 사용 중인 닉네임입니다.';
        _isCheckingNickname = false;
        _saving = false;
      });
      return;
    }

    // 2) 이미지 업로드(있으면)
    String? imageUrl = _photoUrl;
    if (_selectedImage != null) {
      try {
        imageUrl = await _uploadProfileImage(_selectedImage!);
      } catch (_) {
        // 업로드 실패해도 닉변은 진행 가능. 필요하면 에러 처리 추가.
      }
    }

    try {
      // 3) 트랜잭션: 새 닉 예약 -> 옛 닉 반납 -> 프로필 갱신
      await _fs.runTransaction((tx) async {
        final usersRef = _fs.collection(_colUsers).doc(uid);
        final userDoc = await tx.get(usersRef);
        final oldNickRaw = ((userDoc.data()?['nickname']) ??
                (userDoc.data()?['displayName']) ??
                '')
            .toString()
            .trim();
        final oldNickId = oldNickRaw.toLowerCase();

        // 새 닉 문서
        final newRef = _fs.collection(_colUsernames).doc(newNickId);
        final newSnap = await tx.get(newRef);
        if (newSnap.exists) {
          final owner = (newSnap.data()?['uid'] as String?) ?? '';
          if (owner != uid) {
            throw Exception('nickname_taken');
          }
        } else {
          tx.set(newRef, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 옛 닉 반납(내가 소유한 경우만)
        if (oldNickId.isNotEmpty && oldNickId != newNickId) {
          final oldRef = _fs.collection(_colUsernames).doc(oldNickId);
          final oldSnap = await tx.get(oldRef);
          if (oldSnap.exists && (oldSnap.data()?['uid'] == uid)) {
            tx.delete(oldRef);
          }
        }

        // 프로필 갱신
        tx.set(usersRef, {
          'displayName': newNickRaw,
          'nickname': newNickRaw,
          'photoUrl': imageUrl,
          'bio': bio,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // 4) Auth 프로필 동기화
      await _auth.currentUser!.updateDisplayName(newNickRaw);
      if (imageUrl != null) {
        await _auth.currentUser!.updatePhotoURL(imageUrl);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );
      Navigator.pushReplacementNamed(context, '/mypage');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nicknameError =
            e.toString().contains('nickname_taken') ? '이미 사용 중인 닉네임입니다.' : '저장 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingNickname = false;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                          color: Colors.black.withOpacity(0.45),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
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
                        helperText: (_nicknameCtrl.text.isEmpty || _nicknameError != null)
                            ? null
                            : '한글/영문/숫자/_ 2~20자',
                      ),
                      onChanged: (v) {
                        // 형식 가이드 + 오류 초기화
                        if (_nicknameError != null) {
                          setState(() => _nicknameError = null);
                        }
                        setState(() {}); // helperText 갱신용
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: _isCheckingNickname
                          ? null
                          : () async {
                              final nickname = _nicknameCtrl.text.trim();
                              if (!Validators.isNicknameValid(nickname)) {
                                setState(() => _nicknameError = '닉네임 형식을 확인해주세요. (한글/영문/숫자/_ 2~20자)');
                                return;
                              }
                              setState(() => _isCheckingNickname = true);
                              final taken = await _isNicknameTaken(nickname);
                              if (!mounted) return;
                              setState(() {
                                _isCheckingNickname = false;
                                _nicknameError = taken ? '이미 사용 중인 닉네임입니다.' : null;
                              });
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('닉네임 확인'),
                                  content: Text(taken ? '이미 사용 중인 닉네임입니다.' : '사용 가능한 닉네임입니다.'),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                onPressed: _saving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
