import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:haru_diary/widgets/cloud_card.dart';
import 'package:haru_diary/theme/app_theme.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int _currentIndex = 3; // 0: 홈, 1: AI 채팅, 2: 통계, 3: 마이페이지

  String weatherToImage(String? weather) {
    switch (weather) {
      case 'sunny':
        return 'assets/images/sunny.png';
      case 'partly_cloudy':
        return 'assets/images/partly_cloudy.png';
      case 'cloudy':
        return 'assets/images/cloudy.png';
      case 'rainy': // 표준 키
      case 'rain':  // 구버전 호환
        return 'assets/images/rainy.png';
      case 'storm':
        return 'assets/images/storm.png';
      case 'snow':
        return 'assets/images/snow.png';
      default:
        return 'assets/images/cloudy.png';
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return '';
  }

  void showDiaryModal({
    required BuildContext context,
    required String title,
    required String content,
    required String createdAt,
    required String weatherCode,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: CloudCard(
          radius: 20,
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520, maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 메타(날짜/날씨)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      createdAt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                    ),
                    Image.asset(
                      weatherToImage(weatherCode),
                      width: 28,
                      height: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        content,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _onItemTapped(int idx) {
    if (idx == _currentIndex) return;
    switch (idx) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/ai_chat');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/statistics');
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      extendBody: true,

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 프로필 카드
              CloudCard(
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: (user?.photoURL == null || user!.photoURL!.isEmpty)
                          ? Icon(Icons.person, size: 40, color: cs.outline)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? '닉네임',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? 'example@email.com',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed('/fix_profile'),
                      child: const Text('프로필 편집'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 최근 쓴 일기 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최근 쓴 일기',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/diary_list'),
                    child: const Text('더 보기'),
                  ),
                ],
              ),

              // 최근 일기 2개
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
                      child: Text(
                        '최근 쓴 일기가 없습니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.outline),
                      ),
                    );
                  }

                  final diaries = snapshot.data!.docs;
                  return Column(
                    children: diaries.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final title = data['title'] ?? '';
                      final content = (data['content'] ?? data['text'] ?? '') as String; // ✅ 키 불일치 보정
                      final createdAt = data['createdAt'];
                      final weather = data['weather'];

                      return CloudCard(
                        radius: 20,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Image.asset(
                            weatherToImage(weather),
                            width: 32,
                            height: 32,
                          ),
                          title: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${formatTimestamp(createdAt)} · $content',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            showDiaryModal(
                              context: context,
                              title: title,
                              content: content,
                              createdAt: formatTimestamp(createdAt),
                              weatherCode: weather ?? '',
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 설정/로그아웃 카드
              CloudCard(
                radius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('앱 설정'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: 설정 화면 라우팅
                      },
                    ),
                    Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('로그아웃'),
                      onTap: () => showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 바텀 네비게이션: 테마 기반 + 상단 1px 라인
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? Colors.white : cs.surface,
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: cs.onSurface.withValues(alpha: 0.45),
            selectedLabelStyle: const TextStyle(fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            showUnselectedLabels: true,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'AI 채팅'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '통계'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '마이페이지'),
            ],
          ),
        ),
      ),
    );
  }
}
