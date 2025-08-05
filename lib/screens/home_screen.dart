import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/custom_bottom_navbar.dart';

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
      final newEvents = <DateTime, List<Map<String, String>>>{};
      for (var doc in snap.docs) {
        final data = doc.data();
        final ts = (data['date'] as Timestamp).toDate();
        final day = DateTime(ts.year, ts.month, ts.day);
        final weather = data['weather'] as String;
        final title = data['title'] as String? ?? '';
        final content = data['content'] as String? ?? '';
        newEvents.putIfAbsent(day, () => []).add({
          'code': weather,
          'title': title,
          'content': content,
          'id': doc.id,
        });
      }
      setState(() => _events = newEvents);
    });
  }

  Future<void> _fetchWeather() async {
  try {
    // 위치 서비스 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        location = '위치 서비스 꺼짐';
        weatherDesc = '위치 서비스를 켜주세요';
      });
      return;
    }

    // 권한 확인 및 요청
    LocationPermission permission = await Geolocator.checkPermission();
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

    // 위치 가져오기
    Position position = await Geolocator.getCurrentPosition();

    // 도시명 가져오기
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final city = placemarks.first.administrativeArea ??
        placemarks.first.locality ??
        '알 수 없음';

    // API 키 확인
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("API 키가 없습니다. .env를 확인하세요.");
    }

    // API 요청
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=${position.latitude}&lon=${position.longitude}'
      '&appid=$apiKey&units=metric&lang=kr',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception("날씨 API 요청 실패: ${response.statusCode}");
    }

    final data = json.decode(response.body);

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
    print('날씨 정보를 불러오는 중 오류 발생: $e');
  }
}


  String _getWeatherImageFileName(String desc) {
    if (desc.contains('맑음')) return 'sunny';
    if (desc.contains('구름') && desc.contains('약간')) return 'partly_cloudy';
    if (desc.contains('흐림') || desc.contains('구름')) return 'cloudy';
    if (desc.contains('비')) return 'rainy';
    if (desc.contains('눈')) return 'snow';
    return 'cloudy';
  }

  Color _colorFor(String code) {
    switch (code) {
      case 'sunny':
        return Color(0xFFFF9800);
      case 'cloudy':
        return Color(0xFF81D4FA);
      case 'rain':
        return Color(0xFF90A4AE);
      case 'storm':
        return Color(0xFF1565C0);
      case 'snow':
        return Color(0xFFFF5252);
      default:
        return Color(0xFF009688);
    }
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    final dayEvents = _events[DateTime(selected.year, selected.month, selected.day)] ?? [];
    if (dayEvents.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')} 일기',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...dayEvents.map((e) {
              final code = e['code']!;
              final title = e['title']!;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: _colorFor(code)),
                  title: Text(title),
                  onTap: () => _showDiaryDetailModal(context, e, selected),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showDiaryDetailModal(BuildContext context, Map<String, String> diary, DateTime selected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _colorFor(diary['code'] ?? ''),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    diary['title'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              diary['content'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('수정'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/write',
                      arguments: {'date': selected, 'id': diary['id'], 'edit': true},
                    );
                  },
                ),
                TextButton(
                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('diaries')
                        .doc(diary['id'])
                        .delete();
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0064FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${temperature.toStringAsFixed(1)}°',
                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(weatherDesc, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(location, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    Image.asset(
                      'assets/images/${_getWeatherImageFileName(weatherDesc)}.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: TableCalendar<Map<String, String>>(
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: '월'},
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronVisible: false,
                    rightChevronVisible: false,
                  ),
                  daysOfWeekHeight: 20,
                  rowHeight: 56,
                  eventLoader: (day) => _events[DateTime(day.year, day.month, day.day)] ?? [],
                  calendarStyle: const CalendarStyle(
                    markersMaxCount: 1,
                    defaultTextStyle: TextStyle(color: Colors.white70),
                    weekendTextStyle: TextStyle(color: Colors.white),
                    outsideTextStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 하단 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("글쓰기"),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/write',
                        arguments: {'date': _selectedDay ?? DateTime.now()},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0064FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text("글목록"),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/diary_list');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 네브바
          SafeArea(
            top: false,
            child: CustomBottomNavBar(
              currentIndex: 0,
              onTap: (idx) {
                if (idx == 1) Navigator.pushReplacementNamed(context, '/ai_chat');
                if (idx == 2) Navigator.pushReplacementNamed(context, '/statistics');
                if (idx == 3) Navigator.pushReplacementNamed(context, '/mypage');
              },
              icons: const [
                Icons.home,
                Icons.chat, // AI 채팅
                Icons.bar_chart,
                Icons.person,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
