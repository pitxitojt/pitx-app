import 'package:flutter/material.dart';
import 'package:pitx/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchNotifications();
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
        fetchNotifications(); // Refresh data
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
                await fetchNotifications();
              }
            },
          )
          .subscribe();
    } catch (e) {
      print('Error setting up subscription: $e');
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final user_id = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('notifications')
          .select('created_at, title, body, is_read')
          .eq('user_id', user_id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          notifications = List<Map<String, dynamic>>.from(
            response as List<dynamic>,
          );
        });
      }

      // update read status
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user_id)
          .eq('is_read', false);
    } catch (e) {
      print("Error fetching notifications: $e");
      // Handle error, maybe show a snackbar or dialog
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper function to format elapsed time
  String formatElapsedTime(String createdAt) {
    try {
      final DateTime created = DateTime.parse(createdAt);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(created);

      final int minutes = difference.inMinutes;
      final int hours = difference.inHours;
      final int days = difference.inDays;
      final int weeks = (days / 7).floor();
      final int months = (days / 30).floor();
      final int years = (days / 365).floor();

      if (years >= 1) {
        return years == 1 ? '1 year ago' : '$years years ago';
      } else if (months >= 1) {
        return months == 1 ? '1 month ago' : '$months months ago';
      } else if (weeks >= 1) {
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (days >= 1) {
        return days == 1 ? '1 day ago' : '$days days ago';
      } else if (hours >= 1) {
        return hours == 1 ? '1 hour ago' : '$hours hours ago';
      } else if (minutes >= 1) {
        return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error parsing date: $e');
      return 'Unknown time';
    }
  }

  Widget generateNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle notification tap
            print("Tapped on ${notification['title']}");
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (!(notification['is_read'] ?? false))
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  notification['body'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      formatElapsedTime(notification['created_at']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Colors.white,
            ],
            stops: [0.0, 0.5, 0.7],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern hero section with gradient (now in scrollable content)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.transparent),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Updates & Alerts",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Stay Informed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Important updates and announcements from PITX',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Notifications content
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.notifications_active,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'All Notifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Notification cards
                      if (_isLoading)
                        Center(
                          heightFactor: 12,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      else
                        ...notifications.map((notification) {
                          return generateNotificationCard(notification);
                        }).toList(),

                      // Empty state or additional content
                      if (!_isLoading && notifications.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'We\'ll notify you when there are updates',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Add extra bottom padding
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
