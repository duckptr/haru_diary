import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:haru_diary/widgets/cloud_card.dart';
import 'package:haru_diary/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> _events = {};
  String location = '위치를 가져오는 중...'; // ← 오타 수정
  String weatherDesc = '-';
  double temperature = 0;
  int _currentIndex = 0;

  // 날짜를 '연-월-일'만 남기고 00:00:00으로 정규화
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    return _events[_normalize(day)] ?? const [];
  }

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

        // 🔧 날짜 필드 보정: date가 없으면 createdAt 사용
        final Timestamp? tsRaw =
            (data['date'] as Timestamp?) ?? (data['createdAt'] as Timestamp?);
        if (tsRaw == null) continue;
        final ts = tsRaw.toDate();
        final day = _normalize(ts);

        newEvents.putIfAbsent(day, () => []).add({
          'code': (data['weather'] as String?) ?? '',
          'title': (data['title'] as String?) ?? '',
          'content':
              (data['content'] as String?) ?? (data['text'] as String?) ?? '',
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
      final city =
          pms.first.administrativeArea ?? pms.first.locality ?? '알 수 없음';
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

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = _normalize(selected);
      _focusedDay = focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 20 + bottomInset),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 히어로 카드
                CloudCard(
                  radius: 24,
                  padding: const EdgeInsets.all(20),
                  color: AppTheme.primaryBlue,
                  elevation: 0.7,
                  clip: true,
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
                CloudCard(
                  radius: 24,
                  padding: const EdgeInsets.all(12),
                  elevation: 0.5,
                  child: TableCalendar<Map<String, String>>(
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) =>
                        isSameDay(_normalize(d), _selectedDay),
                    onDaySelected: _onDaySelected,
                    onPageChanged: (d) => setState(() => _focusedDay = d),
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: '월'
                    },
                    // ✅ 이벤트 로더 추가: 이게 있어야 마커가 뜹니다
                    eventLoader: _getEventsForDay,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon:
                          Icon(Icons.chevron_left, color: cs.onSurface),
                      rightChevronIcon:
                          Icon(Icons.chevron_right, color: cs.onSurface),
                      titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    daysOfWeekHeight: 30,
                    rowHeight: 56,
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: theme.textTheme.bodyMedium!,
                      weekendTextStyle: theme.textTheme.bodyMedium!,
                      outsideTextStyle: theme.textTheme.bodyMedium!.copyWith(
                        color: cs.outline,
                      ),
                      todayDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryBlue),
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      // ✅ 마커(점) 데코 지정(색상/모양)
                      markerDecoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      markersAlignment: Alignment.bottomCenter,
                      markersMaxCount: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ 선택 날짜 글 목록
                CloudCard(
                  radius: 20,
                  padding: const EdgeInsets.all(12),
                  elevation: 0.5,
                  child: selectedEvents.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '선택한 날짜에 작성한 글이 없습니다.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: cs.outline),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedEvents.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color:
                                cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                          itemBuilder: (context, idx) {
                            final e = selectedEvents[idx];
                            return ListTile(
                              leading: const Icon(Icons.book_outlined),
                              title: Text(
                                e['title']?.isNotEmpty == true
                                    ? e['title']!
                                    : '제목 없음',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                e['content'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                // 글 상세로 이동하고 싶다면 id 사용
                                // Navigator.pushNamed(context, '/write', arguments: {...});
                              },
                            );
                          },
                        ),
                ),

                const SizedBox(height: 24),

                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 22),
                        label: const Text(
                          "글쓰기",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/write',
                            arguments: {
                              'date': _selectedDay ?? DateTime.now()
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.list, size: 22),
                        label: const Text(
                          "글목록",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          // ✅ pushReplacementNamed → pushNamed 로 변경
                          Navigator.pushNamed(context, '/diary_list');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          side: BorderSide(color: cs.outlineVariant),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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

      // 바텀 네비
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color:
              theme.brightness == Brightness.light ? Colors.white : cs.surface,
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
              BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline), label: 'AI 채팅'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart), label: '통계'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: '마이페이지'),
            ],
          ),
        ),
      ),
    );
  }
}
