import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 달력용 상태
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 날짜별 날씨 코드 리스트 저장
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Firestore 일기 스트림 구독
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaries')
        .snapshots()
        .listen((snap) {
      final newEvents = <DateTime, List<String>>{};
      for (var doc in snap.docs) {
        final data = doc.data();
        final ts = (data['date'] as Timestamp).toDate();
        final day = DateTime(ts.year, ts.month, ts.day);
        final weather = data['weather'] as String;
        newEvents.putIfAbsent(day, () => []).add(weather);
      }
      setState(() => _events = newEvents);
    });
  }

  /// 선택된 날짜의 일기를 Firestore에서 읽어와 모달로 보여줍니다.
  Future<void> _showEntriesFor(DateTime day) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaries')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date', descending: true)
        .get();

    final docs = snapshot.docs;
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해당 날짜에 작성된 일기가 없습니다.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, ctl) => ListView.builder(
          controller: ctl,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data    = docs[i].data();
            final title   = data['title']   as String? ?? '';
            final text    = data['text']    as String? ?? '';
            final weather = data['weather'] as String? ?? '';
            final ts      = (data['date']   as Timestamp).toDate();
            final timeStr = '${ts.hour.toString().padLeft(2, '0')}:'
                              '${ts.minute.toString().padLeft(2, '0')}';

            return ListTile(
              leading: Text(_iconFor(weather), style: const TextStyle(fontSize: 24)),
              title: Text(
                title.isNotEmpty ? title : text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(timeStr),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(title.isNotEmpty ? title : '내용'),
                    content: Text(text),
                    actions: [
                            // 삭제 버튼
      TextButton(
        onPressed: () async {
          Navigator.pop(context); // 다이얼로그 닫기
          // Firestore에서 문서 삭제
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('diaries')
              .doc(docs[i].id)
              .delete();
          // 삭제 피드백
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일기가 삭제되었습니다.')),
          );
        },
        child: const Text(
          '삭제',
          style: TextStyle(color: Colors.red),
        ),
      ),
                      // ① 수정 버튼
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // 다이얼로그 닫고
                          // 글쓰기 화면으로 이동하면서 인자 전달
                          Navigator.pushNamed(
                            context,
                            '/write',
                            arguments: {
                              'docId': docs[i].id,
                              'title': title,
                              'text': text,
                              'weather': weather,
            },
          );
        },
        child: const Text('수정'),
      ),
      // ② 닫기 버튼
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),  
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // 날씨 코드 → 이모지
  String _iconFor(String code) {
    switch (code) {
      case 'sunny':  return '☀️';
      case 'cloudy': return '⛅';
      case 'rain':   return '🌧️';
      case 'storm':  return '🌩️';
      case 'snow':   return '❄️';
      default:       return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 API로 오늘 날씨 가져오기
    final todayWeather = '☀️';

    return Scaffold(
      appBar: AppBar(title: const Text('하루 일기')),
      body: Column(
        children: [
          // 오늘의 날씨 카드
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('오늘의 날씨: ', style: Theme.of(context).textTheme.titleMedium),
                    Text(todayWeather, style: const TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
          ),

          // 달력
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay:  DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay  = focused;
                  });
                  _showEntriesFor(selected); // 선택된 날 일기 모달 호출
                },
                eventLoader: (day) =>
                    _events[DateTime(day.year, day.month, day.day)] ?? [],
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final list = events.cast<String>();
                    if (list.isEmpty) return const SizedBox();
                    return Text(
                      _iconFor(list.first),
                      style: const TextStyle(fontSize: 18),
                    );
                  },
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.indigoAccent),
                  selectedDecoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.blue),
                ),
              ),
            ),
          ),
        ],
      ),

      // 일기 작성 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/write'),
        child: const Icon(Icons.edit),
      ),

      // 하단 네비게이션바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),  label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.list),  label: '일기 목록'),
          BottomNavigationBarItem(icon: Icon(Icons.person),label: '마이페이지'),
        ],
        onTap: (idx) {
          if (idx == 1) Navigator.pushNamed(context, '/diary_list');
          if (idx == 2) Navigator.pushNamed(context, '/mypage');
        },
      ),
    );
  }
}

