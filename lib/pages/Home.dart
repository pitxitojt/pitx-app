import 'package:flutter/material.dart';

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
                  width: 180,
                  child: Text(
                    "first-ever landport in the country",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 18,
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
                  Container(
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

          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
