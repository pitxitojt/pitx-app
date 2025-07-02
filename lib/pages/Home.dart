import 'package:flutter/material.dart';
import 'package:pitx/screens/Notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  static final List<Map<String, dynamic>> menu = [
    {'icon': Icons.map, 'label': 'Bus Schedule'},
    {'icon': Icons.directions_bus, 'label': 'Bus Operators'},
    {'icon': Icons.fastfood, 'label': 'Food'},
    {'icon': Icons.search, 'label': 'FAQs'},
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

Widget generateCarousel(List<Map<String, dynamic>> items) {
  final List<Widget> carouselItems = items.map((item) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: SizedBox(
        width: 125,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 170,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(item['image'], fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item['label'],
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }).toList();

  return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: 125),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
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
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary, // Set icon color
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const Notifications(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0); // Slide from right
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
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Image.asset('assets/logo.png', fit: BoxFit.contain, height: 20),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // Black background image
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.black,
              ),
              SizedBox(
                width: double.infinity,
                height: 225,
                child: Opacity(
                  opacity: 0.8,
                  child: Image.asset('assets/bays.jpg', fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: 18,
                left: 18,
                child: SizedBox(
                  width: 210,
                  child: Text(
                    "first-ever landport in the country",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: Home.menu.map((item) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      // Handle tap on menu item
                      print("Tapped on ${item['label']}");
                    },
                    borderRadius: BorderRadius.circular(
                      999,
                    ), // ripple stays circular
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          item['icon'],
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 25,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // FIXED HEIGHT Text area
                  SizedBox(
                    width: 80,
                    height:
                        34, // fixed height to allow 2 lines max (adjust as needed)
                    child: Text(
                      item['label'],
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          // ── HERE: Basic CarouselView ──
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Popular Destinations",
                textAlign: TextAlign.left,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          generateCarousel(Home.destinations),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Explore food options",
                textAlign: TextAlign.left,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          generateCarousel(Home.foodOptions),
        ],
      ),
    );
  }
}
