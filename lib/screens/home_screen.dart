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

  // 날씨 코드 → 이모지
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

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 API로 오늘 날씨 가져오기
    final todayWeather = '☀️';

    return Scaffold(
      appBar: AppBar(title: const Text('하루 일기')),
      body: Column(
        children: [
          // 1) 오늘의 날씨 카드
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '오늘의 날씨: ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(todayWeather, style: const TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
          ),
          // 2) 달력 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  // TODO: 선택된 날 일기 모달 띄우기
                },
                // 4) 이벤트 로더에 _events 연결
                eventLoader: (day) =>
                    _events[DateTime(day.year, day.month, day.day)] ?? [],
                // 5) 달력 셀에 이모지 표시
  calendarBuilders: CalendarBuilders(
  markerBuilder: (context, day, events) {
    final list = events.cast<String>();      // List<dynamic> → List<String>
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
      // 3) 일기 작성으로 가는 FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/write'),
        child: const Icon(Icons.edit),
      ),
      // (선택) 하단 네비게이션바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '일기 목록'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
        onTap: (idx) {
          if (idx == 1) Navigator.pushNamed(context, '/diary_list');
          if (idx == 2) Navigator.pushNamed(context, '/mypage');
        },
      ),
    );
  }
}
