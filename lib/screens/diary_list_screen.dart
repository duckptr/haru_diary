import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  String _searchText = '';
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('작성한 일기 목록'),
        actions: [
          // 날짜 초기화 버튼
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '날짜 검색 해제',
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 제목 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchText = value.trim()),
                    decoration: InputDecoration(
                      hintText: '제목으로 검색',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 날짜 선택 버튼
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: '날짜로 검색',
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('diaries')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                // 필터: 제목+날짜
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title']?.toString() ?? '';

                  // 날짜 필터
                  if (_selectedDate != null) {
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    if (createdAt == null) return false;
                    // 연/월/일이 모두 동일해야 true
                    if (createdAt.year != _selectedDate!.year ||
                        createdAt.month != _selectedDate!.month ||
                        createdAt.day != _selectedDate!.day) {
                      return false;
                    }
                  }
                  // 제목 키워드 필터
                  if (_searchText.isNotEmpty &&
                      !title.contains(_searchText)) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('검색 결과가 없습니다.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? '(제목 없음)';
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();
                    final weather = data['weather'] ?? '';
                    String weatherEmoji = '🌞';
                    switch (weather) {
                      case 'sunny':
                        weatherEmoji = '☀️';
                        break;
                      case 'cloudy':
                        weatherEmoji = '⛅';
                        break;
                      case 'rain':
                        weatherEmoji = '🌧️';
                        break;
                      case 'storm':
                        weatherEmoji = '🌩️';
                        break;
                      case 'snow':
                        weatherEmoji = '❄️';
                        break;
                    }

                    return ListTile(
                      leading: Text(weatherEmoji,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(title),
                      subtitle: Text(
                        createdAt != null
                            ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
                            : '',
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(title),
                            content: Text(data['text'] ?? ''),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('일기 삭제'),
                                      content: const Text('정말 삭제할까요?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('삭제',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('diaries')
                                        .doc(doc.id)
                                        .delete();
                                  }
                                },
                                child: const Text('삭제',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    '/write',
                                    arguments: {
                                      'docId': doc.id,
                                      'title': data['title'],
                                      'text': data['text'],
                                      'weather': data['weather'],
                                    },
                                  );
                                },
                                child: const Text('수정'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('닫기'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
