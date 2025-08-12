import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  const SettingsScreen({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = mode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: const Text('라이트가 기본, 필요할 때 다크 사용'),
            value: isDark,
            onChanged: (v) => onChanged(v ? ThemeMode.dark : ThemeMode.light),
          ),
          const Divider(),
          ListTile(
            title: const Text('시스템 테마 따라가기'),
            subtitle: const Text('선택 시 기기 설정에 맞춰 자동 전환'),
            trailing: mode == ThemeMode.system
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}
