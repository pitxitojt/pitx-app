import 'package:flutter/material.dart';
import 'package:pitx/pages/BusOperators.dart';
import 'package:pitx/pages/BusSchedules.dart';
import 'package:pitx/pages/FAQ.dart';
import 'package:pitx/pages/Food.dart';
import 'package:pitx/screens/Notifications.dart';
import 'package:pitx/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
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
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // Label positioned over the gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    item['label'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
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

class _HomeState extends State<Home> with WidgetsBindingObserver {
  int _unreadNotificationCount = 0;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchNotificationCount();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is back from background - reconnect subscription
        _reconnectSubscription();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is going to background - no action needed
        break;
    }
  }

  void _reconnectSubscription() {
    // Unsubscribe existing channel
    _channel?.unsubscribe();

    // Wait a bit for cleanup then reconnect
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _setupRealtimeSubscription();
        _fetchNotificationCount(); // Refresh data
      }
    });
  }

  void _setupRealtimeSubscription() {
    try {
      _channel = supabase
          .channel(
            'public:notifications_${DateTime.now().millisecondsSinceEpoch}',
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) async {
              print('Notification payload: $payload');
              if (mounted) {
                await _fetchNotificationCount();
              }
            },
          )
          .subscribe();
    } catch (e) {
      print('Error setting up subscription: $e');
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('notifications')
            .select('is_read')
            .eq('user_id', user.id)
            .eq('is_read', false);

        if (mounted) {
          setState(() {
            _unreadNotificationCount = response.length;
          });
        }
      }
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: Colors.white),
                  tooltip: 'Notifications',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.1),
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const Notifications(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
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
                        )
                        .then((_) {
                          // Refresh notification count when returning from notifications page
                          _fetchNotificationCount();
                        });
                  },
                ),
                // Red notification indicator
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        _unreadNotificationCount > 9
                            ? '9+'
                            : _unreadNotificationCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Image.asset(
          'assets/logo-short.png',
          fit: BoxFit.contain,
          height: 24,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.35),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.5],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Hero Section with modern design
              Container(
                height: 280,
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
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
                        ),
                      ),
                      // Enhanced gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Welcome content with improved styling
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Welcome to PITX",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Philippines' First-Ever\nLandport Terminal",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Your gateway to seamless travel experiences",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Enhanced Quick Actions Section
              Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bolt,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Quick Actions",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
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
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.05),
                                      Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.02),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(context).primaryColor,
                                              Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          item['icon'],
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        item['label'],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Enhanced Popular Destinations Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.explore,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Popular Destinations",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              "See all",
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),

              generateCarousel(Home.destinations),

              SizedBox(height: 32),

              // Enhanced Food Options Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.restaurant,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Food & Dining",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => Food()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "See all",
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),

              generateCarousel(Home.foodOptions, isFood: true),

              // Bottom spacing
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
