import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> _events = {};
  String location = '위치를 가져오는 중...';
  String weatherDesc = '-';
  double temperature = 0;
  int _currentIndex = 0; // 0: 홈, 1: AI 채팅, 2: 통계, 3: 마이페이지

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _loadEvents();
    _selectedDay = _focusedDay;
  }

  void _loadEvents() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaries')
        .snapshots()
        .listen((snap) {
      final newEvents = <DateTime, List<Map<String, String>>>{};
      for (var doc in snap.docs) {
        final data = doc.data();
        final ts = (data['date'] as Timestamp).toDate();
        final day = DateTime(ts.year, ts.month, ts.day);
        newEvents.putIfAbsent(day, () => []).add({
          'code': data['weather'] as String,
          'title': data['title'] as String? ?? '',
          'content': data['content'] as String? ?? '',
          'id': doc.id,
        });
      }
      if (mounted) setState(() => _events = newEvents);
    });
  }

  Future<void> _fetchWeather() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          location = '위치 서비스 꺼짐';
          weatherDesc = '위치 서비스를 켜주세요';
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            location = '위치 권한 없음';
            weatherDesc = '권한 허용이 필요합니다';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          location = '위치 권한 거부됨';
          weatherDesc = '설정에서 권한을 허용해주세요';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final pms = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final city = pms.first.administrativeArea ?? pms.first.locality ?? '알 수 없음';
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("API 키가 없습니다. .env를 확인하세요.");
      }

      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&appid=$apiKey&units=metric&lang=kr',
      );
      final resp = await http.get(url);
      if (resp.statusCode != 200) {
        throw Exception("날씨 API 요청 실패: ${resp.statusCode}");
      }
      final data = json.decode(resp.body);
      if (!mounted) return;
      setState(() {
        location = city;
        weatherDesc = data['weather'][0]['description'] ?? '-';
        temperature = (data['main']['temp'] ?? 0).toDouble();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        location = '날씨 정보 오류';
        weatherDesc = e.toString();
      });
    }
  }

  String _getWeatherImageFileName(String desc) {
    if (desc.contains('맑음')) return 'sunny';
    if (desc.contains('구름')) return 'cloudy';
    if (desc.contains('비')) return 'rainy';
    if (desc.contains('눈')) return 'snow';
    return 'cloudy';
  }

  Color _colorFor(String code) {
    switch (code) {
      case 'sunny':
        return const Color(0xFFFF9800);
      case 'cloudy':
        return const Color(0xFF81D4FA);
      case 'rain':
        return const Color(0xFF90A4AE);
      case 'storm':
        return const Color(0xFF1565C0);
      case 'snow':
        return const Color(0xFFFF5252);
    }
    return const Color(0xFF009688);
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 20 + bottomInset),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // 날씨 카드
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0064FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${temperature.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weatherDesc,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/images/${_getWeatherImageFileName(weatherDesc)}.png',
                        width: 64,
                        height: 64,
                        errorBuilder: (c, _, __) => const Icon(
                          Icons.wb_sunny,
                          color: Colors.yellow,
                          size: 64,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 캘린더 카드
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TableCalendar<Map<String, String>>(
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                    onDaySelected: _onDaySelected,
                    onPageChanged: (d) => setState(() => _focusedDay = d),
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {CalendarFormat.month: '월'},
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronVisible: true,
                      rightChevronVisible: true,
                      titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    daysOfWeekHeight: 30,
                    rowHeight: 56,
                    calendarStyle: const CalendarStyle(
                      defaultTextStyle: TextStyle(color: Colors.white70),
                      weekendTextStyle: TextStyle(color: Colors.white),
                      outsideTextStyle: TextStyle(color: Colors.white38),
                      todayDecoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF0064FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 글쓰기 / 글목록 버튼
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 22),
                        label: const Text(
                          "글쓰기",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/write',
                            arguments: { 'date': _selectedDay ?? DateTime.now() },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0064FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.list, size: 22),
                        label: const Text(
                          "글목록",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/diary_list');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424242),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          showUnselectedLabels: true,
          onTap: (idx) {
            if (idx == _currentIndex) return;
            setState(() => _currentIndex = idx);
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
                Navigator.pushReplacementNamed(context, '/mypage');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'AI 채팅'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '통계'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '마이페이지'),
          ],
        ),
      ),
    );
  }
}
