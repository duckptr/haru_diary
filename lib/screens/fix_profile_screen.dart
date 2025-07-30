import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _loadCurrentUserData() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      _nicknameCtrl.text = data['displayName'] ?? '';
      _bioCtrl.text = data['bio'] ?? '';
      _photoUrl = data['photoUrl'];
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _selectedImage = File(image.path);
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_photoUrl != null ? NetworkImage(_photoUrl!) : null)
                            as ImageProvider?,
                    child: _selectedImage == null && _photoUrl == null
                        ? const Icon(Icons.person, size: 48, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nicknameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: _nicknameError,
                    ),
                    onChanged: (_) {
                      if (_nicknameError != null) {
                        setState(() {
                          _nicknameError = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nickname = _nicknameCtrl.text.trim();
                      if (nickname.isEmpty) return;

                      setState(() => _isCheckingNickname = true);
                      final isDuplicate = await _isNicknameDuplicate(nickname);
                      setState(() {
                        _isCheckingNickname = false;
                        _nicknameError = isDuplicate ? '이미 사용 중인 닉네임입니다.' : null;
                      });

                      if (!mounted) return;

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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0064FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 20),

            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '자기소개',
                labelStyle: const TextStyle(color: Colors.white),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0064FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveProfile,
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
