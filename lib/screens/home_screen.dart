import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ dotenv import
import '../widgets/custom_bottom_navbar.dart'; // ✅ 공용 바텀네브바

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};

  String location = '위치를 가져오는 중...';
  String weatherDesc = '-';
  double temperature = 0;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _loadEvents();
  }

  void _loadEvents() {
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

  Future<void> _fetchWeather() async {
    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final city = placemarks.first.administrativeArea ??
        placemarks.first.locality ??
        '알 수 없음';

    final apiKey = dotenv.env['OPENWEATHER_API_KEY']!; // ✅ .env에서 키 로딩
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=kr',
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    setState(() {
      location = city;
      weatherDesc = data['weather'][0]['description'];
      temperature = data['main']['temp'];
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
                leading:
                    Text(_iconFor(weather), style: const TextStyle(fontSize: 24)),
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
                          child: const Text('삭제', style: TextStyle(color: Colors.red)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('하루 일기')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날씨 카드
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temperature.toStringAsFixed(1)}°',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weatherDesc,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // 캘린더
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

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/write'),
          child: const Icon(Icons.edit),
        ),
      ),

      // ✅ 공용 바텀 네비게이션 바 사용
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (idx) {
          if (idx == 1) Navigator.pushReplacementNamed(context, '/diary_list');
          if (idx == 2) Navigator.pushReplacementNamed(context, '/statistics');
          if (idx == 3) Navigator.pushReplacementNamed(context, '/mypage');
        },
      ),
    );
  }
}
