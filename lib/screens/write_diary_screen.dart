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
  final _textCtrl = TextEditingController();

  String? _weatherCode;
  String? _docId;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 수정 모드 인자 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _isEditing = true;
          _docId = args['docId'] as String?;
          _titleCtrl.text = args['title'] as String? ?? '';
          _textCtrl.text = args['text'] as String? ?? '';
          _weatherCode = args['weather'] as String?;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWeather() async {
    final icons = {
      'sunny': '☀️',
      'cloudy': '⛅',
      'rain': '🌧️',
      'storm': '🌩️',
      'snow': '❄️',
    };
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => GridView.count(
        crossAxisCount: 5,
        padding: const EdgeInsets.all(16),
        children: icons.entries.map((e) {
          final selected = e.key == _weatherCode;
          return IconButton(
            onPressed: () => Navigator.pop(context, e.key),
            icon: Text(
              e.value,
              style: TextStyle(
                fontSize: 24,
                color: selected ? Colors.blue : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
    if (choice != null) {
      setState(() {
        _weatherCode = choice;
      });
    }
  }

  Future<void> _onSubmit() async {
    final title = _titleCtrl.text.trim();
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    if (_weatherCode == null) {
      // 날씨 미선택 시 자동 호출
      await _pickWeather();
      if (_weatherCode == null) return;
    }

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaries');

    try {
      if (_isEditing && _docId != null) {
        await col.doc(_docId).update({
          'title': title,
          'text': text,
          'weather': _weatherCode!,
          'date': DateTime.now(),
        });
      } else {
        await col.add({
          'title': title,
          'text': text,
          'weather': _weatherCode!,
          'date': DateTime.now(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '일기 수정' : '일기 작성'),
      ),
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

            // 날씨 선택 요약
            if (_weatherCode != null)
              Text(
                '선택된 날씨: ${_iconFor(_weatherCode!)}',
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 8),

            // 작성/수정 완료 버튼
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _onSubmit,
                    child: Text(_isEditing ? '수정 완료' : '작성 완료'),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickWeather,
        tooltip: '날씨 선택',
        child: const Icon(Icons.emoji_emotions_outlined),
      ),
    );
  }

  String _iconFor(String code) {
    switch (code) {
      case 'sunny':
        return '☀️';
      case 'cloudy':
        return '⛅';
      case 'rain':
        return '🌧️';
      case 'storm':
        return '🌩️';
      case 'snow':
        return '❄️';
      default:
        return '';
    }
  }
}
