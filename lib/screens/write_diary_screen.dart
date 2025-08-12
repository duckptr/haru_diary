import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ 추가: 구름 카드 & 테마 색
import 'package:haru_diary/widgets/cloud_card.dart';
import 'package:haru_diary/theme/app_theme.dart';

class WriteDiaryScreen extends StatefulWidget {
  const WriteDiaryScreen({super.key});

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  final _titleCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _tagInputCtrl = TextEditingController();

  String? _weatherCode;
  String? _docId;   // 사용자 서브콜렉션 문서 id
  String? _rootId;  // 루트 콜렉션(diaries) 문서 id
  bool _isEditing = false;
  bool _isLoading = false;
  DateTime? _selectedDate;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    // 라우트 인자 파싱
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        // 편집 여부 판단: rootId 또는 docId가 있으면 편집 모드로 간주
        final hasRootId = args.containsKey('rootId') && args['rootId'] != null;
        final hasDocId = args.containsKey('docId') && args['docId'] != null;

        // DiaryList(루트)에서 넘어온 경우: docId는 루트 id이므로 rootId로 사용, user doc id는 모름
        if (!hasRootId && hasDocId) {
          _rootId = args['docId'] as String?;
          _docId = null; // 사용자 문서 id는 나중에 조회
        } else {
          _rootId = args['rootId'] as String?;
          _docId = args['docId'] as String?;
        }

        _isEditing = (_rootId != null) || (_docId != null);
        _titleCtrl.text = args['title'] as String? ?? '';
        _textCtrl.text = args['text'] as String? ?? '';
        _weatherCode = args['weather'] as String?;
        final tagList = args['hashtags'] as List<dynamic>? ?? [];
        _tags = tagList.map((e) => e.toString()).toList();
        _selectedDate = args['createdAt'] != null
            ? (args['createdAt'] as Timestamp).toDate()
            : (args['date'] as DateTime?) ?? DateTime.now();
      } else {
        _selectedDate = DateTime.now();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  void _handleTagInput(String value) {
    if (value.endsWith(' ')) {
      final tag = value.trim();
      final validTag = RegExp(r'^[a-zA-Z0-9가-힣]+$');

      if (tag.isEmpty || !validTag.hasMatch(tag)) {
        _tagInputCtrl.clear();
        return;
      }
      if (_tags.contains(tag)) {
        _tagInputCtrl.clear();
        return;
      }
      if (_tags.length >= 5) {
        _tagInputCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해시태그는 최대 5개까지 입력할 수 있어요.')),
        );
        return;
      }
      setState(() {
        _tags.add(tag);
        _tagInputCtrl.clear();
      });
    }
  }

  void _showWeatherDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '당신의 하루는 어땠나요?',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _weatherIconOption('sunny', 'sunny.png'),
            _weatherIconOption('partly_cloudy', 'partly_cloudy.png'),
            _weatherIconOption('cloudy', 'cloudy.png'),
            _weatherIconOption('rainy', 'rainy.png'),
            _weatherIconOption('storm', 'storm.png'),
          ],
        ),
      ),
    );
  }

  Widget _weatherIconOption(String code, String assetName) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _weatherCode = code);
        Navigator.pop(context);
        _onSubmit();
      },
      child: SizedBox(
        width: 54,
        height: 54,
        child: Image.asset(
          'assets/images/$assetName',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Future<void> _ensureUserDocIdFromRoot() async {
    // _docId가 없고 _rootId만 있을 때, 사용자 서브콜렉션에서 rootId로 문서를 찾는다.
    if (_docId != null || _rootId == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDiaryCol =
        FirebaseFirestore.instance.collection('users').doc(uid).collection('diaries');

    final q = await userDiaryCol.where('rootId', isEqualTo: _rootId).limit(1).get();
    if (q.docs.isNotEmpty) {
      _docId = q.docs.first.id;
    }
  }

  Future<void> _onSubmit() async {
    final title = _titleCtrl.text.trim();
    final content = _textCtrl.text.trim();

    if (content.isEmpty) return;
    if (_weatherCode == null) {
      _showWeatherDialog();
      return;
    }

    final createdDate = _selectedDate ?? DateTime.now();

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDiaryCol =
        FirebaseFirestore.instance.collection('users').doc(uid).collection('diaries');
    final rootDiaryCol = FirebaseFirestore.instance.collection('diaries');

    final data = {
      'uid': uid,
      'title': title,
      'content': content,
      'weather': _weatherCode!,
      'hashtags': _tags,
      'createdAt': Timestamp.fromDate(createdDate),
      'date': createdDate,
    };

    try {
      if (_isEditing) {
        // 편집: 케이스별 처리
        // 1) rootId만 있는 경우(user 문서 id 모름) -> 조회해서 업데이트
        await _ensureUserDocIdFromRoot();

        if (_rootId != null) {
          await rootDiaryCol.doc(_rootId).update(data);
        }
        if (_docId != null) {
          await userDiaryCol.doc(_docId).update({
            ...data,
            'rootId': _rootId ?? _docId, // 안전장치
          });
        } else {
          // user 문서가 없었으면 새로 만들어 일관성 유지
          await userDiaryCol.add({
            ...data,
            'rootId': _rootId,
          });
        }
      } else {
        // 신규 작성: root에 먼저 저장하고 user에 same rootId로 저장
        final rootRef = await rootDiaryCol.add(data);
        final rootId = rootRef.id;
        await userDiaryCol.add({
          ...data,
          'rootId': rootId,
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDelete() async {
    if (!_isEditing || _rootId == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDiaryCol =
        FirebaseFirestore.instance.collection('users').doc(uid).collection('diaries');
    final rootDiaryCol = FirebaseFirestore.instance.collection('diaries');

    try {
      // user 문서 id가 없으면 조회 후 삭제 시도
      await _ensureUserDocIdFromRoot();
      if (_docId != null) {
        await userDiaryCol.doc(_docId).delete();
      }
      await rootDiaryCol.doc(_rootId).delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '일기 수정' : '일기 작성'),
        actions: [
          IconButton(
            tooltip: '날씨 선택',
            icon: const Icon(Icons.wb_sunny_outlined),
            onPressed: _showWeatherDialog,
          ),
          if (_isEditing)
            IconButton(
              tooltip: '삭제',
              icon: const Icon(Icons.delete_outline),
              onPressed: _onDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 제목
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: CloudCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),

            // 본문 (확장 영역)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CloudCard(
                  radius: 20,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _textCtrl,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: '오늘 하루의 이야기를 기록해 보세요',
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 16),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ),
            ),

            // 태그 + 입력
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CloudCard(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: -8,
                      children: _tags
                          .map((tag) => Chip(
                                label: Text('#$tag'),
                                onDeleted: () {
                                  setState(() => _tags.remove(tag));
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tagInputCtrl,
                      onChanged: _handleTagInput,
                      decoration: const InputDecoration(
                        labelText: '해시태그 입력 (예: 공부 운동)',
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 작성/수정 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _onSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(_isEditing ? '수정 완료' : '작성 완료'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
