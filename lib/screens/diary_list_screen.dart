import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:haru_diary/widgets/custom_bottom_navbar.dart';

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

  void _onTabTapped(int index) {
    const routes = ['/home', '/diary_list', '/statistics', '/mypage'];
    if (ModalRoute.of(context)?.settings.name != routes[index]) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    final diaryStream = FirebaseFirestore.instance
        .collection('diaries')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('일기 목록')),
      body: StreamBuilder<QuerySnapshot>(
        stream: diaryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('작성한 일기가 없습니다.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final content = data['content'] ?? ''; // ✅ 필드명 통일
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              final formatted =
                  date != null ? DateFormat('yyyy.MM.dd').format(date) : '';
              final hashtagsRaw = data['hashtags'];
              final List<String> hashtags = hashtagsRaw != null
                  ? List<String>.from(hashtagsRaw as List)
                  : [];

              return GestureDetector(
                onTap: () => _showDetailModal(
                  context: context,
                  docId: docs[index].id,
                  title: title,
                  content: content,
                  formatted: formatted,
                  hashtags: hashtags,
                ),
                child: SizedBox(
                  height: 150,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(formatted, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 4,
                            runSpacing: -8,
                            children: hashtags
                                .map((tag) => Chip(label: Text('#$tag')))
                                .toList(),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: _onTabTapped,
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
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, ctl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: ctl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(formatted, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 16),
                Text(content, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 6,
                  children: hashtags.map((tag) => Chip(label: Text('#$tag'))).toList(),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/write',
                            arguments: {
                              'docId': docId,
                              'title': title,
                              'text': content, // WriteDiaryScreen 내부에서는 'text'로 받음
                              'hashtags': hashtags,
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('수정'),
                      ),
                    ),
                    const SizedBox(width: 16), // ✅ 버튼 간격 추가
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirebaseFirestore.instance
                              .collection('diaries')
                              .doc(docId)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('일기가 삭제되었습니다.')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('삭제'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
