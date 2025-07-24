import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _submitProfile() async {
    if (_nickCtrl.text.isEmpty || _bioCtrl.text.isEmpty) {
      setState(() => _error = '닉네임과 소개는 반드시 입력해야 합니다.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String photoUrl = '';
      if (_image != null) {
        final ref = FirebaseStorage.instance.ref('user_profiles/$uid.jpg');
        await ref.putFile(_image!);
        photoUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'nickname': _nickCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'photoUrl': photoUrl,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _error = '저장 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '사진은 선택사항입니다',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nickCtrl,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioCtrl,
              decoration: const InputDecoration(labelText: '자기소개'),
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Text(
                _error,
                style: const TextStyle(color: Colors.red),
              ),
            const Spacer(),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitProfile,
                    child: const Text('완료'),
                  ),
          ],
        ),
      ),
    );
  }
}
