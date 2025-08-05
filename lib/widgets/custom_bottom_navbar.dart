import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<IconData> icons;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.icons = const [
      Icons.home,
      Icons.list,
      Icons.bar_chart,
      Icons.person,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 25,
        currentIndex: currentIndex,
        onTap: onTap,
        items: icons
            .map((icon) => BottomNavigationBarItem(
                  icon: Icon(icon),
                  label: '',
                ))
            .toList(),
      ),
    );
  }
}
