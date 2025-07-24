import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WriteDiaryScreen extends StatefulWidget {
  const WriteDiaryScreen({super.key});

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  final _titleCtrl = TextEditingController();
  final _textCtrl  = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final title = _titleCtrl.text.trim();
    final text  = _textCtrl.text.trim();
    if (text.isEmpty) return;

    // 1) 날씨 선택
    final weather = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        final icons = {
          'sunny': '☀️',
          'cloudy': '⛅',
          'rain': '🌧️',
          'storm': '🌩️',
          'snow': '❄️',
        };
        return GridView.count(
          crossAxisCount: 5,
          padding: const EdgeInsets.all(16),
          children: icons.entries.map((e) {
            return IconButton(
              onPressed: () => Navigator.pop(context, e.key),
              icon: Text(e.value, style: const TextStyle(fontSize: 24)),
            );
          }).toList(),
        );
      },
    );
    if (weather == null) return; // 취소

    // 2) Firestore에 저장 (제목(title) 포함)
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaries')
        .add({
      'title': title,
      'text': text,
      'weather': weather,
      'date': DateTime.now(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3) 뒤로 돌아가기
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일기 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 제목 입력란
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),

            // 본문 입력란
            Expanded(
              child: TextField(
                controller: _textCtrl,
                decoration: const InputDecoration(
                  hintText: '오늘 하루의 이야기를 기록해 보세요',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12), 
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 12),

            // 작성 완료 버튼
            ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}
