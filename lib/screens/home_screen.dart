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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.2,
        maxChildSize: 0.85,
        builder: (_, ctl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView.builder(
            controller: ctl,
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final title = data['title'] as String? ?? '';
              final text = data['text'] as String? ?? '';
              final weather = data['weather'] as String? ?? '';
              final ts = (data['date'] as Timestamp).toDate();
              final timeStr =
                  '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

              return ListTile(
                leading: Text(_iconFor(weather),
                    style: const TextStyle(fontSize: 24)),
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
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('diaries')
                                .doc(docs[i].id)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('일기가 삭제되었습니다.')),
                            );
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
                                'docId': docs[i].id,
                                'title': title,
                                'text': text,
                                'weather': weather,
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
          ),
        ),
      ),
    );
  }

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
    final todayWeather = '☀️';

    return Scaffold(
      appBar: AppBar(title: const Text('하루 일기')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('오늘의 날씨: ',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(todayWeather, style: const TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
          ),
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
                  _showEntriesFor(selected);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/write'),
        child: const Icon(Icons.edit),
      ),
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
