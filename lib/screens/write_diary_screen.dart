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
  final _tagCtrl = TextEditingController();

  String? _weatherCode;
  String? _docId;
  String? _rootId;
  bool _isEditing = false;
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        setState(() {
          _isEditing = args['docId'] != null;
          _docId = args['docId'] as String?;
          _rootId = args['rootId'] as String?;
          _titleCtrl.text = args['title'] as String? ?? '';
          _textCtrl.text = args['text'] as String? ?? '';
          _weatherCode = args['weather'] as String?;
          final tags = args['hashtags'] as List<dynamic>? ?? [];
          _tagCtrl.text = tags.map((e) => '#$e').join(' ');
          _selectedDate = args['createdAt'] != null
              ? (args['createdAt'] as Timestamp).toDate()
              : (args['date'] as DateTime?) ?? DateTime.now();
        });
      } else {
        _selectedDate = DateTime.now();
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _showWeatherDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('당신의 하루는 어땠나요?'),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            _weatherIconOption('sunny', '☀️'),
            _weatherIconOption('cloudy', '⛅'),
            _weatherIconOption('rain', '🌧️'),
            _weatherIconOption('storm', '🌩️'),
            _weatherIconOption('snow', '❄️'),
          ],
        ),
      ),
    );
  }

  Widget _weatherIconOption(String code, String icon) {
    return GestureDetector(
      onTap: () {
        setState(() => _weatherCode = code);
        Navigator.pop(context);
        _onSubmit();
      },
      child: Text(icon, style: const TextStyle(fontSize: 30)),
    );
  }

  List<String> _extractHashtags(String input) {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(input).map((m) => m.group(1)!).toList();
  }

  Future<void> _onSubmit() async {
    final title = _titleCtrl.text.trim();
    final content = _textCtrl.text.trim();
    final tags = _extractHashtags(_tagCtrl.text);

    if (content.isEmpty) return;
    if (_weatherCode == null) {
      _showWeatherDialog();
      return;
    }

    final createdDate = _selectedDate ?? DateTime.now();

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDiaryCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('diaries');
    final rootDiaryCol = FirebaseFirestore.instance.collection('diaries');

    final data = {
      'uid': uid,
      'title': title,
      'content': content,
      'weather': _weatherCode!,
      'hashtags': tags,
      'createdAt': Timestamp.fromDate(createdDate),
      'date': createdDate,
    };

    try {
      if (_isEditing && _docId != null && _rootId != null) {
        await userDiaryCol.doc(_docId).update(data);
        await rootDiaryCol.doc(_rootId).update(data);
      } else {
        final rootRef = await rootDiaryCol.add(data);
        final rootId = rootRef.id;
        final userData = {
          ...data,
          'rootId': rootId,
        };
        await userDiaryCol.add(userData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDelete() async {
    if (!_isEditing || _docId == null || _rootId == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDiaryCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('diaries');
    final rootDiaryCol = FirebaseFirestore.instance.collection('diaries');

    try {
      await userDiaryCol.doc(_docId).delete();
      await rootDiaryCol.doc(_rootId).delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '일기 수정' : '일기 작성'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _onDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '오늘 하루의 이야기를 기록해 보세요',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagCtrl,
              decoration: const InputDecoration(
                labelText: '해시태그 (예: #공부 #운동)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _onSubmit,
                    child: Text(_isEditing ? '수정 완료' : '작성 완료'),
                  ),
          ],
        ),
      ),
    );
  }
}
