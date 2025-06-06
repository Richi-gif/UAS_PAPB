import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:praktikum_1/views/My_Reviews.dart';
import 'package:praktikum_1/views/home.dart';
import 'package:praktikum_1/views/settings.dart';

class CustomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  const CustomNavigationBar({required this.selectedIndex, super.key});

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  void _onItemTapped(int index) {
    if (index == widget.selectedIndex) {
      return;
    }

    Widget nextPage = const HomePage();

    switch (index) {
      case 0:
        nextPage = const HomePage();
        break;
      case 1:
        nextPage = const MyReviewsPage();
        break;
      case 2:
        nextPage = const MyWidget();
        break;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 12,
      color: const Color.fromARGB(255, 23, 26, 33),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(FontAwesome.house_chimney_solid, 'Home', 0),
          _buildNavItem(FontAwesome.gamepad_solid, 'My Review', 1),
          _buildNavItem(FontAwesome.user_solid, 'Account', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = widget.selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color.fromARGB(255, 102, 192, 244)
                    : Colors.grey),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color.fromARGB(255, 102, 192, 244)
                    : Colors.grey,
                fontSize: 14, // Set font size here
              ),
            ),
          ],
        ),
      ),
    );
  }
}
