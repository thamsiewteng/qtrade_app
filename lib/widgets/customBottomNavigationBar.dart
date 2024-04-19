import 'package:flutter/material.dart';
import 'package:qtrade_app/screen/algorithmPage.dart';
import 'package:qtrade_app/screen/homePage.dart';
import 'package:qtrade_app/screen/tradingPage.dart';

import '../screen/strategyPage.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavigationBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF261c4f),
      unselectedItemColor: Color.fromARGB(255, 171, 163, 202),
      currentIndex: currentIndex,
      onTap: (index) {
        if (currentIndex == index)
          return; // Do nothing if the current tab is reselected
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AlgorithmPage()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StrategyPage()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TradingPage()),
            );
          // Add other cases for each tab
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.computer),
          label: 'Algorithm',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: 'Strategy',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Trading',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}
