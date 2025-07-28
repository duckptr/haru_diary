import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:haru_diary/widgets/custom_bottom_navbar.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  String weatherToEmoji(String? weather) {
    switch (weather) {
      case 'sunny':
        return '☀️';
      case 'cloudy':
        return '☁️';
      case 'rainy':
        return '🌧️';
      case 'storm':
        return '🌩️';
      case 'snow':
        return '❄️';
      default:
        return '🌈';
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return '';
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('네'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('아니오'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/', (route) => false);
      });
    }
  }

  void showDiaryModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.blue.shade50,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(BuildContext context, int index) {
    const routes = ['/home', '/diary_list', '/statistics', '/mypage'];
    if (ModalRoute.of(context)?.settings.name != routes[index]) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? '닉네임',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? 'example@email.com',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('최근 쓴 일기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pushNamed('/diary_list');
                    },
                    child: const Text('더 보기'),
                  ),
                ],
              ),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('diaries')
                    .orderBy('createdAt', descending: true)
                    .limit(2)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        '최근 쓴 일기가 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  final diaries = snapshot.data!.docs;
                  return Column(
                    children: diaries.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Text(
                            weatherToEmoji(data['weather']),
                            style: const TextStyle(fontSize: 28),
                          ),
                          title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${formatTimestamp(data['createdAt'])} · ${data['text'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            showDiaryModal(
                              context,
                              data['title'] ?? '',
                              data['text'] ?? '',
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('앱 설정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: () {
                  showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: CustomBottomNavBar(
            currentIndex: 3,
            onTap: (index) => _onTabTapped(context, index),
          ),
        ),
      ),
    );
  }
}
