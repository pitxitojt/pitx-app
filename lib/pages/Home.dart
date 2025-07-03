import 'package:flutter/material.dart';
import 'package:pitx/pages/BusOperators.dart';
import 'package:pitx/pages/BusSchedules.dart';
import 'package:pitx/pages/FAQ.dart';
import 'package:pitx/pages/Food.dart';
import 'package:pitx/screens/Notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  static final List<Map<String, dynamic>> menu = [
    {'icon': Icons.map, 'label': 'Bus Schedules', 'page': BusSchedules()},
    {
      'icon': Icons.directions_bus,
      'label': 'Bus Operators',
      'page': BusOperators(),
    },
    {'icon': Icons.fastfood, 'label': 'Food', 'page': Food()},
    {'icon': Icons.search, 'label': 'FAQs', 'page': FAQ()},
  ];

  static final List<Map<String, dynamic>> destinations = [
    {'label': 'Batangas', 'image': 'assets/batangas.jpg'},
    {'label': 'Bicol', 'image': 'assets/bicol.jpg'},
    {'label': 'Davao', 'image': 'assets/davao.jpg'},
    {'label': 'Tagaytay', 'image': 'assets/tagaytay.jpg'},
  ];

  static final List<Map<String, dynamic>> foodOptions = [
    {'label': 'Jollibee', 'image': 'assets/jollibee.png'},
    {'label': 'McDonald\'s', 'image': 'assets/mcdonalds.jpg'},
    {'label': 'Chowking', 'image': 'assets/chowking.png'},
  ];

  @override
  State<Home> createState() => _HomeState();
}

Widget generateCarousel(
  List<Map<String, dynamic>> items, {
  bool isFood = false,
}) {
  final List<Widget> carouselItems = items.map((item) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                height: 100,
                child: Image.asset(
                  item['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        isFood ? Icons.fastfood : Icons.location_on,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                item['label'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }).toList();

  return Container(
    height: 140,
    child: ListView(
      padding: EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      children: carouselItems,
    ),
  );
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.1),
            ),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const Notifications(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;

                        final tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
            },
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Image.asset('assets/logo.png', fit: BoxFit.contain, height: 24),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with improved design
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background image with better overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/bays.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Welcome content
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Welcome to PITX",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Philippines' First-Ever\nLandport Terminal",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Your gateway to seamless travel experiences",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions Section with improved design
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: Home.menu.length,
                      itemBuilder: (context, index) {
                        final item = Home.menu[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      item['page'] ?? Container(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      item['icon'],
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    item['label'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Popular Destinations Section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.explore,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Popular Destinations",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to all destinations
                        },
                        child: Text(
                          "See all",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),

            generateCarousel(Home.destinations),

            SizedBox(height: 32),

            // Food Options Section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Food & Dining",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => Food()),
                          );
                        },
                        child: Text(
                          "See all",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),

            generateCarousel(Home.foodOptions, isFood: true),

            // Bottom spacing
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
