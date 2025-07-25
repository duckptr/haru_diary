import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:haru_diary/widgets/custom_bottom_navbar.dart'; // ✅ 네비게이션 바 import

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
              final content = data['content'] ?? '';
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              final formatted =
                  date != null ? DateFormat('yyyy.MM.dd').format(date) : '';
              final hashtags = data['hashtags'] is List
                  ? List<String>.from(data['hashtags'])
                  : [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatted),
                      const SizedBox(height: 4),
                      Text(content,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: hashtags
                            .map((tag) => Chip(label: Text('#$tag')))
                            .toList(),
                      )
                    ],
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(formatted,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            Text(content),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              children: hashtags
                                  .map((tag) => Chip(label: Text('#$tag')))
                                  .toList(),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // ✅ 공통 하단 네비게이션 바 적용
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: _onTabTapped,
      ),
    );
  }
}
