import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class BusSchedules extends StatefulWidget {
  const BusSchedules({super.key});

  @override
  State<BusSchedules> createState() => _BusSchedulesState();
}

class _BusSchedulesState extends State<BusSchedules>
    with WidgetsBindingObserver {
  // Dummy data for bus schedules
  List<Map<String, dynamic>>? _schedules;
  List<Map<String, dynamic>>? _filteredSchedules;
  String? _errorMessage = null;
  bool _isLoading = true;
  Timer? _refreshTimer;
  late tz.Location _manilaLocation;

  // Search and filter variables
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedStatusFilter = 'All Statuses';
  String selectedTimeFilter = 'All Times';
  List<String> availableStatuses = ['All Statuses'];
  List<String> availableTimeRanges = [
    'All Times',
    'Morning (5AM-12PM)',
    'Afternoon (12PM-6PM)',
    'Evening (6PM-12AM)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTimezone();
    searchController.addListener(_onSearchChanged);
    fetchSchedules();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
    });
    _applyFilters();
  }

  void _applyFilters() {
    if (_schedules == null) return;

    setState(() {
      _filteredSchedules = _schedules!
          .map((timeGroup) {
            List<Map<String, dynamic>>
            filteredSchedules = timeGroup['schedules']
                .where((schedule) {
                  bool matchesSearch = true;
                  bool matchesStatus = true;
                  bool matchesTime = true;

                  // Search filter (destination/route and operator)
                  if (searchQuery.isNotEmpty) {
                    String route = schedule['route']?.toLowerCase() ?? '';
                    String operator = schedule['operator']?.toLowerCase() ?? '';
                    matchesSearch =
                        route.contains(searchQuery) ||
                        operator.contains(searchQuery);
                  }

                  // Status filter
                  if (selectedStatusFilter != 'All Statuses') {
                    matchesStatus = schedule['status'] == selectedStatusFilter;
                  }

                  // Time filter
                  if (selectedTimeFilter != 'All Times') {
                    matchesTime = _matchesTimeRange(
                      timeGroup['time'],
                      selectedTimeFilter,
                    );
                  }

                  return matchesSearch && matchesStatus && matchesTime;
                })
                .toList()
                .cast<Map<String, dynamic>>();

            return {'time': timeGroup['time'], 'schedules': filteredSchedules};
          })
          .where((timeGroup) => timeGroup['schedules'].isNotEmpty)
          .toList();
    });
  }

  bool _matchesTimeRange(String timeStr, String timeRange) {
    try {
      DateTime scheduledTime = parseScheduledTime(timeStr);
      int hour = scheduledTime.hour;

      switch (timeRange) {
        case 'Morning (5AM-12PM)':
          return hour >= 5 && hour < 12;
        case 'Afternoon (12PM-6PM)':
          return hour >= 12 && hour < 18;
        case 'Evening (6PM-12AM)':
          return hour >= 18 && hour < 24;
        default:
          return true;
      }
    } catch (e) {
      return true;
    }
  }

  void _updateAvailableFilters() {
    if (_schedules == null) return;

    Set<String> statuses = {'All Statuses'};

    for (var timeGroup in _schedules!) {
      for (var schedule in timeGroup['schedules']) {
        statuses.add(schedule['status'] ?? '');
      }
    }

    setState(() {
      availableStatuses = statuses.toList()..sort();
    });
  }

  void _resetFilters() {
    setState(() {
      searchController.clear();
      searchQuery = '';
      selectedStatusFilter = 'All Statuses';
      selectedTimeFilter = 'All Times';
    });
    _applyFilters();
  }

  void _initializeTimezone() {
    tz.initializeTimeZones();
    _manilaLocation = tz.getLocation('Asia/Manila');
  }

  // Get current Manila time regardless of device timezone
  DateTime get _currentManilaTime {
    return tz.TZDateTime.now(_manilaLocation);
  }

  // Transform API data into the expected format
  List<Map<String, dynamic>> transformApiData(List<dynamic> apiData) {
    Map<String, List<Map<String, dynamic>>> groupedByTime = {};

    // Get current Manila time for filtering
    DateTime manilaTime = _currentManilaTime;

    for (var item in apiData) {
      if (item is List && item.length >= 6) {
        String time = item[2] ?? ''; // Time is at index 2
        String operatorCode = item[0] ?? ''; // Operator code at index 0
        String operator = item.length > 10
            ? (item[10] ?? operatorCode)
            : operatorCode; // Full name at index 10
        String route = item[3] ?? ''; // Route name at index 3
        String gate = item[4] ?? ''; // Gate at index 4
        String bay = item[5] ?? ''; // Bay at index 5

        // Remove the | at the end of route if it exists
        route = route.replaceAll('|', '');

        // Determine status based on available data
        String status = determineStatus(item);

        // Check if this schedule should be included
        bool shouldInclude = shouldIncludeSchedule(time, status, manilaTime);

        if (shouldInclude) {
          Map<String, dynamic> schedule = {
            'operator': operator,
            'route': route,
            'gate': gate,
            'bay': bay,
            'status': status,
          };

          if (!groupedByTime.containsKey(time)) {
            groupedByTime[time] = [];
          }
          groupedByTime[time]!.add(schedule);
        }
      }
    }

    // Convert grouped data to the expected format and sort schedules within each time
    List<Map<String, dynamic>> result = [];
    groupedByTime.forEach((time, schedules) {
      // Sort schedules within this time group by gate and bay
      schedules.sort((a, b) => compareGateAndBay(a, b));
      result.add({'time': time, 'schedules': schedules});
    });

    // Sort by time - AM first, then PM, both in ascending order
    result.sort((a, b) => compareTimeStrings(a['time'], b['time']));

    return result;
  }

  // Helper function to compare schedules by gate and bay numbers
  int compareGateAndBay(Map<String, dynamic> a, Map<String, dynamic> b) {
    // Extract gate numbers
    int gateA = extractNumber(a['gate'] ?? '');
    int gateB = extractNumber(b['gate'] ?? '');

    // First sort by gate
    if (gateA != gateB) {
      return gateA.compareTo(gateB);
    }

    // If gates are the same, sort by bay
    int bayA = extractNumber(a['bay'] ?? '');
    int bayB = extractNumber(b['bay'] ?? '');

    return bayA.compareTo(bayB);
  }

  // Helper function to extract numbers from strings like "G05", "D35", etc.
  int extractNumber(String text) {
    if (text.isEmpty) return 0;

    // Remove all non-digit characters and parse the number
    String numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isEmpty) return 0;

    try {
      return int.parse(numbers);
    } catch (e) {
      return 0;
    }
  }

  // Helper function to determine if a schedule should be included
  bool shouldIncludeSchedule(
    String timeStr,
    String status,
    DateTime manilaTime,
  ) {
    try {
      DateTime scheduledTime = parseScheduledTime(timeStr);

      // Always include cancelled schedules regardless of time
      if (['CANCELLED', 'DELAYED', 'DEPARTED'].contains(status.toUpperCase())) {
        return true;
      }

      // For non-cancelled schedules, only include if not yet passed
      bool hasNotPassed = scheduledTime.isAfter(manilaTime);

      return hasNotPassed;
    } catch (e) {
      // If we can't parse the time, include it to be safe
      return true;
    }
  }

  // Helper function to compare time strings properly
  int compareTimeStrings(String timeA, String timeB) {
    try {
      // Parse both times
      DateTime parsedTimeA = parseScheduledTime(timeA);
      DateTime parsedTimeB = parseScheduledTime(timeB);

      // Get hours in 24-hour format for comparison
      int hourA = parsedTimeA.hour;
      int hourB = parsedTimeB.hour;
      int minuteA = parsedTimeA.minute;
      int minuteB = parsedTimeB.minute;

      // Create comparable values (AM times: 0-11, PM times: 12-23)
      int comparableA = hourA * 60 + minuteA;
      int comparableB = hourB * 60 + minuteB;

      return comparableA.compareTo(comparableB);
    } catch (e) {
      // If parsing fails, fall back to string comparison
      return timeA.compareTo(timeB);
    }
  }

  String determineStatus(List<dynamic> item) {
    String status = item[17];
    if (status == "") {
      if (item[6] == "8") {
        status = "ARRIVING";
      } else if (item[6] == "0") {
        status = "TBD";
      } else if (item[6] == "7") {
        if (item[13] == "1")
          status = "DEPARTED";
        else if (item[13] == "0")
          status = "DELAYED";
      } else if (item[6] == "2") {
        status = "DELAYED";
      } else if (item[6] == "6") {
        status = "BOARDING";
      }
    }
    if (status.isNotEmpty) {
      return status.toUpperCase();
    }

    // // If index 17 is blank, check if within 30 minutes of schedule
    // if (item.length > 2) {
    //   String timeStr = item[2]?.toString() ?? '';
    //   if (timeStr.isNotEmpty) {
    //     try {
    //       // Parse the scheduled time using Manila timezone
    //       DateTime manilaTime = _currentManilaTime;
    //       DateTime scheduledTime = parseScheduledTime(timeStr);

    //       // Check if current time is within 30 minutes before scheduled time
    //       Duration difference = scheduledTime.difference(manilaTime);

    //       if (difference.inMinutes <= 30 && difference.inMinutes >= 0) {
    //         return 'ARRIVING';
    //       }
    //     } catch (e) {
    //       print('Error parsing time: $e');
    //     }
    //   }
    // }

    return 'TBD'; // Default status if not within 30 minutes or time parsing fails
  }

  // Helper function to parse scheduled time
  DateTime parseScheduledTime(String timeStr) {
    // Get current Manila time
    DateTime manilaTime = _currentManilaTime;

    // Remove any extra spaces and convert to uppercase
    timeStr = timeStr.trim().toUpperCase();

    // Extract time components
    bool isPM = timeStr.contains('PM');
    bool isAM = timeStr.contains('AM');

    // Remove AM/PM and clean the string
    String cleanTime = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();

    // Split by colon
    List<String> parts = cleanTime.split(':');
    if (parts.length >= 2) {
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }

      // Create DateTime for today with the parsed time in Manila timezone
      DateTime result = tz.TZDateTime(
        _manilaLocation,
        manilaTime.year,
        manilaTime.month,
        manilaTime.day,
        hour,
        minute,
      );
      return result;
    }

    throw FormatException('Invalid time format: $timeStr');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startRefreshTimer();
      fetchSchedules(showLoading: false);
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchSchedules(showLoading: false);
    });
  }

  Future<void> fetchSchedules({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final url =
          "https://www.pitx.ph/wp-content/themes/sunday-elephant-child-theme/includes/php/departures.php";
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final rawSchedules = jsonData['result'];

        final transformedData = transformApiData(rawSchedules);

        setState(() {
          _schedules = transformedData;
          _errorMessage = null;
        });
        _updateAvailableFilters();
        _applyFilters();
      } else {
        setState(
          () => _errorMessage = 'Failed to fetch data: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to fetch data: $e');
    }
    if (showLoading) {
      setState(() => _isLoading = false);
    }
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ARRIVING':
        return Color(0xFF10B981); // Modern green
      case 'CANCELLED':
        return Color(0xFFEF4444); // Modern red
      case 'TBD':
        return Color(0xFFFFFFFF); // Modern blue
      case 'DELAYED':
        return Color(0xFFF59E0B); // Modern amber
      case 'DEPARTED':
        return Color(0xFF3B82F6); // Modern blue
      default:
        return Color.fromARGB(255, 179, 239, 68); // Default modern blue
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
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Operator
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  schedule['operator'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(width: 8),
            // Route with text wrapping for long destination names
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  schedule['route'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Gate
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${extractNumber(schedule['gate'])}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            // Bay
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${extractNumber(schedule['bay'])}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            // Status
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: getStatusColor(schedule['status']),
                  borderRadius: BorderRadius.circular(20),
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Time header with gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  timeData['time'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Schedule entries container
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                SizedBox(height: 8),
                // Use ListView.builder for better performance
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: timeData['schedules'].length,
                  itemBuilder: (context, index) {
                    return buildScheduleCard(timeData['schedules'][index]);
                  },
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTableHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
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
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Destination',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                    fontSize: 13,
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
                    fontSize: 13,
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
                    fontSize: 13,
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
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'Bus Schedules',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              color: Theme.of(context).colorScheme.primary,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Modern date header (now in scrollable content)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      color: Theme.of(context).colorScheme.primary,
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
                              "Live Schedules",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            getCurrentDate(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Real-time bus schedule information",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search and Filter Section
                    Container(
                      color: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          // Search Bar
                          Container(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search destination or operator...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          searchController.clear();
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 12),

                          // Filter Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedStatusFilter,
                                      hint: Text('Filter by Status'),
                                      isExpanded: true,
                                      items: availableStatuses.map((
                                        String value,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedStatusFilter = newValue!;
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedTimeFilter,
                                      hint: Text('Filter by Time'),
                                      isExpanded: true,
                                      items: availableTimeRanges.map((
                                        String value,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedTimeFilter = newValue!;
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          // Filter Results Count and Reset Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${(_filteredSchedules ?? []).length} time slots',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                              if (searchQuery.isNotEmpty ||
                                  selectedStatusFilter != 'All Statuses' ||
                                  selectedTimeFilter != 'All Times')
                                TextButton(
                                  onPressed: _resetFilters,
                                  child: Text(
                                    'Clear Filters',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Schedule content
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
                          children: _errorMessage != null
                              ? [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                ]
                              : [
                                  buildTableHeader(),
                                  SizedBox(height: 8),
                                  // Use ListView.builder for better performance
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount:
                                        (_filteredSchedules ?? _schedules ?? [])
                                            .length,
                                    itemBuilder: (context, index) {
                                      return buildTimeSection(
                                        (_filteredSchedules ??
                                            _schedules)![index],
                                      );
                                    },
                                  ),
                                  // Add extra bottom padding for better scrolling experience
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
