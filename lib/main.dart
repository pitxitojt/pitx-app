import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pitx/pages/Discover.dart';
import 'package:pitx/pages/Home.dart';
import 'package:pitx/screens/Welcome.dart';
import 'package:pitx/pages/Profile.dart';
import 'package:collection/collection.dart';
import 'package:pitx/pages/Search.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PITX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xff1d439b),
          primary: Color(0xff1d439b),
          onPrimary: Colors.white,
        ),

        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const Initialization(title: 'Flutter Demo Home Page'),
    );
  }
}

class Initialization extends StatefulWidget {
  const Initialization({super.key, required this.title});
  final String title;

  @override
  State<Initialization> createState() => _InitializationState();
}

class _InitializationState extends State<Initialization> {
  int _currentPage = 0;
  bool _isLoggedIn = false;

  final List<Map<String, dynamic>> _bottomNavIcons = [
    {'label': "Home", 'icon': Icons.home, 'page': Home()},
    {'label': "Discover", 'icon': Icons.explore, 'page': Discover()},
    {'label': "Search", 'icon': Icons.search, 'page': Search()},
    {'label': "Profile", 'icon': Icons.person, 'page': Profile()},
  ];

  void setCurrentPage(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Icon generateIcon(IconData icon, int index) {
    return Icon(
      icon,
      color: _currentPage == index ? Colors.white : Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Welcome();
    }
    return Scaffold(
      body: IndexedStack(
        index: _currentPage,
        children: _bottomNavIcons.map((data) {
          return data['page'] as Widget;
        }).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: _bottomNavIcons.mapIndexed((index, data) {
          return NavigationDestination(
            icon: generateIcon(data['icon'], index),
            label: data['label'],
          );
        }).toList(),
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorShape: CircleBorder(),
        selectedIndex: _currentPage,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        onDestinationSelected: setCurrentPage,
      ),
    );
  }
}
