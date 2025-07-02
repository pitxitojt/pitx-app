import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Bus Schedule Update',
      'message':
          'The bus schedule has been updated. Please check the app for details.',
      'date': '2023-10-01',
    },
    {
      'title': 'Maintenance Notice',
      'message':
          'Scheduled maintenance will occur on 2023-10-05. Expect delays.',
      'date': '2023-09-30',
    },
    {
      'title': 'New Feature Alert',
      'message': 'We have added a new feature to enhance your experience.',
      'date': '2023-09-29',
    },
  ];
  Widget generateNotificationCard(notification) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsetsGeometry.all(6),

        child: ListTile(
          title: Text(
            notification['title'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          subtitle: Text(
            notification['message'],
            style: TextStyle(fontSize: 11),
          ),
          trailing: Text(notification['date']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary, // Set icon color
        ),
        centerTitle: true,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(16, 8, 16, 8),
        child: Column(
          spacing: 4,
          children: notifications.map((notification) {
            return generateNotificationCard(notification);
          }).toList(),
        ),
      ),
    );
  }
}
