import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:haru_diary/widgets/bouncy_button.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('일기 목록'),
          automaticallyImplyLeading: true,
          backgroundColor: Colors.black,
        ),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    final diaryStream = FirebaseFirestore.instance
        .collection('diaries')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    final bottomInset = MediaQuery.of(context).padding.bottom + 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 목록'),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: diaryStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('에러 발생: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('작성한 일기가 없습니다.'));
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: bottomInset),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data()! as Map<String, dynamic>;
                        final title = data['title'] ?? '';
                        final content = data['content'] ?? '';
                        final date = (data['createdAt'] as Timestamp?)?.toDate();
                        final formatted = date != null
                            ? DateFormat('yyyy.MM.dd').format(date)
                            : '';
                        final hashtagsRaw = data['hashtags'];
                        final hashtags = hashtagsRaw != null
                            ? List<String>.from(hashtagsRaw as List)
                            : <String>[];
                        final weather = data['weather'];

                        return GestureDetector(
                          onTap: () => _showDetailModal(
                            context: context,
                            docId: doc.id,
                            title: title,
                            content: content,
                            formatted: formatted,
                            hashtags: hashtags,
                            weather: weather,
                          ),
                          child: Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (weather != null)
                                        Image.asset(
                                          'assets/images/$weather.png',
                                          width: 28,
                                          height: 28,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatted,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (hashtags.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: hashtags
                                          .map((t) => Chip(label: Text('#$t')))
                                          .toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal({
    required BuildContext context,
    required String docId,
    required String title,
    required String content,
    required String formatted,
    required List<String> hashtags,
    required String? weather,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, ctl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: ctl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  formatted,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (weather != null)
                  Row(
                    children: [
                      const Text(
                        '날씨:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/$weather.png',
                        width: 32,
                        height: 32,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Text(
                  content,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                if (hashtags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        hashtags.map((t) => Chip(label: Text('#$t'))).toList(),
                  ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: BouncyButton(
                        text: '수정',
                        color: const Color(0xFF0064FF),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('수정 확인'),
                              content: const Text('정말 수정하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('네'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('아니오'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/write',
                              arguments: {
                                'docId': docId,
                                'title': title,
                                'text': content,
                                'hashtags': hashtags,
                              },
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BouncyButton(
                        text: '삭제',
                        color: Colors.red,
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('삭제 확인'),
                              content: const Text(
                                  '정말 삭제하시겠습니까?\n삭제된 일기는 복구할 수 없습니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('네'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('아니오'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            Navigator.pop(context);
                            await FirebaseFirestore.instance
                                .collection('diaries')
                                .doc(docId)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('일기가 삭제되었습니다.')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
