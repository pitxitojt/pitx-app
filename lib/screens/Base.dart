import 'package:flutter/material.dart';
import 'package:pitx/pages/Discover.dart';
import 'package:pitx/pages/Home.dart';
import 'package:pitx/pages/Profile.dart';
import 'package:pitx/pages/Search.dart';
import 'package:collection/collection.dart';
import 'package:pitx/main.dart' show AuthManager;

class Base extends StatefulWidget {
  const Base({super.key});

  @override
  State<Base> createState() => _BaseState();
}

class _BaseState extends State<Base> with WidgetsBindingObserver {
  int _currentPage = 0;

  final List<Map<String, dynamic>> _bottomNavIcons = [
    {'label': "Home", 'icon': Icons.home, 'page': Home()},
    {'label': "Discover", 'icon': Icons.explore, 'page': Discover()},
    {'label': "Search", 'icon': Icons.search, 'page': Search()},
    {'label': "Profile", 'icon': Icons.person, 'page': Profile()},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background
        AuthManager.handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App is coming back from background
        if (AuthManager.handleAppResumed()) {
          // Navigate to login screen if re-authentication is required
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        break;
    }
  }

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
