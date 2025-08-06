import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedMonth = '전체';
  int _currentIndex = 2; // 0: 홈, 1: AI 채팅, 2: 통계, 3: 마이페이지

  final Map<String, String> _emotionMap = const {
    'sunny': '기분 좋음',
    'cloudy': '평범함',
    'rain': '우울함',
    'storm': '짜증남',
    'snow': '차분함',
  };

  List<String> _availableMonths = ['전체'];

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  void _loadAvailableMonths() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('diaries')
        .where('uid', isEqualTo: uid)
        .get();

    final months = <String>{'전체'};
    for (var doc in snapshot.docs) {
      final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        months.add(DateFormat('yyyy-MM').format(createdAt));
      }
    }

    final sorted = months.toList()..sort();
    setState(() => _availableMonths = sorted);
  }

  Future<Map<String, dynamic>> _fetchStatistics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final snapshot = await FirebaseFirestore.instance
        .collection('diaries')
        .where('uid', isEqualTo: uid)
        .get();

    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);

    int total = 0, currentMonthCount = 0;
    final emotionCounts = <String, int>{};
    final monthlyCounts = <String, int>{};
    final weekdayCounts = <int, int>{};
    final hashtagCounts = <String, int>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) continue;

      final monthKey = DateFormat('yyyy-MM').format(createdAt);
      if (_selectedMonth != '전체' && monthKey != _selectedMonth) continue;

      total++;
      if (monthKey == currentMonth) currentMonthCount++;
      monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
      weekdayCounts[createdAt.weekday] =
          (weekdayCounts[createdAt.weekday] ?? 0) + 1;

      final weather = data['weather'] as String? ?? '';
      final emotion = _emotionMap[weather] ?? '기타';
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;

      if (data['hashtags'] is List) {
        for (var tag in List<String>.from(data['hashtags'])) {
          hashtagCounts[tag] = (hashtagCounts[tag] ?? 0) + 1;
        }
      }
    }

    final topTags = hashtagCounts.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {
      'total': total,
      'month': currentMonthCount,
      'emotion': emotionCounts,
      'monthStats': monthlyCounts,
      'weekdayStats': weekdayCounts,
      'topTags': topTags.take(3).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('통계 데이터를 불러올 수 없습니다.'));
            }
            final data = snapshot.data!;
            final emotion = data['emotion'] as Map<String, int>;
            final monthStats = data['monthStats'] as Map<String, int>;
            final weekdayStats = data['weekdayStats'] as Map<int, int>;
            final topTags = data['topTags'] as List<MapEntry<String, int>>;

            return ListView(
              children: [
                Card(
                  child: ListTile(
                    title: Text('📌 총 일기 수: ${data['total']}개'),
                    subtitle: Text('📅 이번 달 작성: ${data['month']}개'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('😊 감정별 일기 수',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...emotion.entries.map((e) => Row(
                              children: [
                                Text(e.key),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: data['total'] > 0
                                        ? e.value / data['total']
                                        : 0,
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${e.value}회'),
                              ],
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('📊 월별 일기 수',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 200, child: _MonthlyChart(data: monthStats)),
                const SizedBox(height: 16),
                const Text('📅 요일별 활동 분석',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 200, child: _WeekdayChart(data: weekdayStats)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🏷 가장 많이 사용한 해시태그',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: topTags
                              .map((e) => Chip(label: Text('#${e.key} (${e.value})')))
                              .toList(),
                        ),
                      ],
                    ),
                  ),  
                ),
              ],
            );  
          },
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
                // 현재 통계 화면  
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

class _MonthlyChart extends StatelessWidget {  
  final Map<String, int> data;  
  const _MonthlyChart({required this.data});  

  @override  
  Widget build(BuildContext context) {  
    final now = DateTime.now();  
    final months = List.generate(6, (i) {  
      final date = DateTime(now.year, now.month - 5 + i);  
      return DateFormat('yyyy-MM').format(date);  
    });  
    final values = months.map((m) => data[m] ?? 0).toList();  
    final labels = months.map((m) => m.substring(5)).toList();  

    return BarChart(  
      BarChartData(  
        alignment: BarChartAlignment.spaceAround,  
        titlesData: FlTitlesData(  
          bottomTitles: AxisTitles(  
            sideTitles: SideTitles(  
              showTitles: true,  
              getTitlesWidget: (v, _) {  
                final idx = v.toInt();  
                return idx >= 0 && idx < labels.length  
                    ? Text(labels[idx], style: const TextStyle(fontSize: 10))  
                    : const SizedBox();  
              },  
              reservedSize: 28,  
            ),  
          ),  
          leftTitles: AxisTitles(  
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),  
          ),  
          rightTitles: AxisTitles(  
            sideTitles: SideTitles(showTitles: false),  
          ),  
          topTitles: AxisTitles(  
            sideTitles: SideTitles(showTitles: false),  
          ),  
        ),  
        barGroups: List.generate(labels.length, (i) {  
          return BarChartGroupData(x: i, barRods: [  
            BarChartRodData(  
              toY: values[i].toDouble(),  
              width: 16,  
              borderRadius: BorderRadius.circular(4),  
            ),  
          ]);  
        }),  
      ),  
    );  
  }  
}

class _WeekdayChart extends StatelessWidget {  
  final Map<int, int> data;  
  const _WeekdayChart({required this.data});  

  @override  
  Widget build(BuildContext context) {  
    final days = ['월', '화', '수', '목', '금', '토', '일'];  
    final values = List.generate(7, (i) => data[i + 1] ?? 0);  

    return BarChart(  
      BarChartData(  
        alignment: BarChartAlignment.spaceAround,  
        titlesData: FlTitlesData(  
          bottomTitles: AxisTitles(  
            sideTitles: SideTitles(  
              showTitles: true,  
              getTitlesWidget: (v, _) {  
                final idx = v.toInt();  
                return idx >= 0 && idx < days.length  
                    ? Text(days[idx], style: const TextStyle(fontSize: 10))  
                    : const SizedBox();  
              },  
              reservedSize: 28,  
            ),  
          ),  
          leftTitles: AxisTitles(  
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),  
          ),  
          rightTitles: AxisTitles(  
            sideTitles: SideTitles(showTitles: false),  
          ),  
          topTitles: AxisTitles(  
            sideTitles: SideTitles(showTitles: false),  
          ),  
        ),  
        barGroups: List.generate(days.length, (i) {  
          return BarChartGroupData(x: i, barRods: [  
            BarChartRodData(  
              toY: values[i].toDouble(),  
              width: 16,  
              borderRadius: BorderRadius.circular(4),  
            ),  
          ]);  
        }),  
      ),  
    );  
  }  
}
