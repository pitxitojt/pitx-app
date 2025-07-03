import 'package:flutter/material.dart';

class BusSchedules extends StatefulWidget {
  const BusSchedules({super.key});

  @override
  State<BusSchedules> createState() => _BusSchedulesState();
}

class _BusSchedulesState extends State<BusSchedules> {
  // Dummy data for bus schedules
  final List<Map<String, dynamic>> busScheduleData = [
    {
      'time': '08:30 AM',
      'schedules': [
        {
          'operator': 'SOLID NORTH',
          'route': 'SAN CARLOS CITY',
          'gate': '4',
          'bay': '20',
          'status': 'CANCELLED',
        },
      ],
    },
    {
      'time': '09:00 AM',
      'schedules': [
        {
          'operator': 'PHILTRANCO',
          'route': 'DAVAO CITY',
          'gate': '2',
          'bay': '8',
          'status': 'ARRIVING',
        },
        {
          'operator': 'DAVAO METRO SHUTTLE',
          'route': 'DAVAO CITY',
          'gate': '2',
          'bay': '9',
          'status': 'CANCELLED',
        },
        {
          'operator': 'SOLID NORTH',
          'route': 'BAGUIO CITY',
          'gate': '4',
          'bay': '20',
          'status': 'CANCELLED',
        },
        {
          'operator': 'SOLID NORTH',
          'route': 'DAGUPAN CITY',
          'gate': '4',
          'bay': '21',
          'status': 'ARRIVING',
        },
        {
          'operator': 'SUPERLINES',
          'route': 'DAET',
          'gate': '4',
          'bay': '23',
          'status': 'ARRIVING',
        },
      ],
    },
    {
      'time': '09:30 AM',
      'schedules': [
        {
          'operator': 'VICTORY LINER',
          'route': 'BAGUIO CITY',
          'gate': '3',
          'bay': '15',
          'status': 'ON TIME',
        },
        {
          'operator': 'GENESIS',
          'route': 'TUGUEGARAO',
          'gate': '5',
          'bay': '25',
          'status': 'DELAYED',
        },
      ],
    },
  ];

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ARRIVING':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'ON TIME':
        return Colors.blue;
      case 'DELAYED':
        return Colors.orange;
      case 'BOARDING':
        return Colors.purple;
      case 'DEPARTED':
        return Colors.grey;
      default:
        return Colors.blue; // Default color
    }
  }

  String getCurrentDate() {
    final now = DateTime.now();
    final days = [
      'SUNDAY',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
    ];
    final months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];

    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget buildScheduleCard(Map<String, dynamic> schedule) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Operator
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  schedule['operator'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            // Route
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  schedule['route'],
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ),
            // Gate
            Expanded(
              flex: 1,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    schedule['gate'],
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ),
            ),
            // Bay
            Expanded(
              flex: 1,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    schedule['bay'],
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: getStatusColor(schedule['status']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      schedule['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTimeSection(Map<String, dynamic> timeData) {
    return Column(
      children: [
        // Time header
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF1E3A8A), // Dark blue
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              timeData['time'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Schedule entries
        ...timeData['schedules']
            .map<Widget>((schedule) => buildScheduleCard(schedule))
            .toList(),
      ],
    );
  }

  Widget buildTableHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Color(0xFF3B82F6), // Blue header
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Operator',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Route',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Gate',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Bay',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        centerTitle: true,
        title: Text(
          'Bus Schedules',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Center(
              child: Text(
                getCurrentDate(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    buildTableHeader(),
                    SizedBox(height: 16),
                    ...busScheduleData
                        .map(
                          (timeData) => Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: buildTimeSection(timeData),
                          ),
                        )
                        .toList(),
                    // Add extra bottom padding for better scrolling experience
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
