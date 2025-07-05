import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:pitx/main.dart';
import 'package:url_launcher/url_launcher.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;

  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Data from API
  List<Map<String, dynamic>> _busOperators = [];
  List<Map<String, dynamic>> _busSchedules = [];

  late tz.Location _manilaLocation;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _initializeTimezone();
    // Remove initial data fetching - only fetch when user searches
  }

  void launchInBrowser(String url) async {
    try {
      // Ensure URL has proper protocol
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }

      final uri = Uri.parse(formattedUrl);

      // Try to launch with external application first
      if (await canLaunchUrl(uri)) {
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          // If external app fails, try platform default
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        // If can't launch, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open browser: $formattedUrl'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle parsing errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeTimezone() {
    tz.initializeTimeZones();
    _manilaLocation = tz.getLocation('Asia/Manila');
  }

  // Get current Manila time regardless of device timezone
  DateTime get _currentManilaTime {
    return tz.TZDateTime.now(_manilaLocation);
  }

  Future<void> _fetchSchedules() async {
    try {
      final url =
          "https://www.pitx.ph/wp-content/themes/sunday-elephant-child-theme/includes/php/departures.php";
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final rawSchedules = jsonData['result'];

        _processScheduleData(rawSchedules);
      } else {
        throw Exception('Failed to fetch schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch schedules: $e');
    }
  }

  Future<void> _refreshData() async {
    // Only refresh if there's an active search
    if (_searchQuery.isNotEmpty) {
      await _fetchDataWithSearch();
    }
  }

  Future<void> _fetchBusOperators() async {
    // Get all destinations first (same as BusOperators.dart)
    final List destinations = await supabase
        .from('destination')
        .select()
        .order('name', ascending: true);

    // For each destination, get the operators that serve it
    Map<String, Map<String, dynamic>> operatorMap = {};

    for (var destination in destinations) {
      String destinationName = destination['name'] ?? '';

      if (destinationName.isNotEmpty) {
        // Get all route IDs for this destination (same logic as BusOperators.dart)
        final List routeRows = await supabase
            .from('routes')
            .select('id, name, destination')
            .eq('destination', destinationName)
            .order('name', ascending: true);

        final List<int> routeIds = routeRows
            .map((r) => r['id'] as int)
            .toList();

        if (routeIds.isNotEmpty) {
          // Get operator routes that match those route IDs (same logic as BusOperators.dart)
          final List operatorRoutes = await supabase
              .from('bus_operator_routes')
              .select('routes(id, name), bus_operators(name, website_url)')
              .inFilter('route_id', routeIds);

          // Process the results
          for (var item in operatorRoutes) {
            String operatorName = item['bus_operators']['name'] ?? '';
            String routeName = item['routes']['name'] ?? '';
            String websiteUrl = item['bus_operators']['website_url'] ?? '';

            if (operatorName.isNotEmpty) {
              if (!operatorMap.containsKey(operatorName)) {
                operatorMap[operatorName] = {
                  'name': operatorName,
                  'routes': <String>[],
                  'destinations': <String>[],
                  'website_url': websiteUrl,
                };
              }

              // Add route if not already present
              if (routeName.isNotEmpty &&
                  !operatorMap[operatorName]!['routes'].contains(routeName)) {
                operatorMap[operatorName]!['routes'].add(routeName);
              }

              // Add destination if not already present
              if (destinationName.isNotEmpty &&
                  !operatorMap[operatorName]!['destinations'].contains(
                    destinationName,
                  )) {
                operatorMap[operatorName]!['destinations'].add(destinationName);
              }
            }
          }
        }
      }
    }

    // Convert to list and sort
    List<Map<String, dynamic>> operators = operatorMap.values.toList();
    operators.sort((a, b) => a['name'].compareTo(b['name']));

    setState(() {
      _busOperators = operators;
    });
  }

  void _processScheduleData(List<dynamic> apiData) {
    List<Map<String, dynamic>> schedules = [];
    Map<String, Set<String>> operatorRoutes = {};

    DateTime manilaTime = _currentManilaTime;

    for (var item in apiData) {
      if (item is List && item.length >= 6) {
        String time = item[2] ?? '';
        String operatorCode = item[0] ?? '';
        String operator = item.length > 10
            ? (item[10] ?? operatorCode)
            : operatorCode;
        String route = item[3] ?? '';
        String gate = item[4] ?? '';
        String bay = item[5] ?? '';

        // Remove the | at the end of route if it exists
        route = route.replaceAll('|', '');

        // Determine status based on available data
        String status = _determineStatus(item);

        // Check if this schedule should be included
        bool shouldInclude = _shouldIncludeSchedule(time, status, manilaTime);

        if (shouldInclude) {
          // Add to schedules
          schedules.add({
            'time': time,
            'operator': operator,
            'route': route,
            'gate': gate,
            'bay': bay,
            'status': status,
          });

          // Group routes by operator
          if (!operatorRoutes.containsKey(operator)) {
            operatorRoutes[operator] = {};
          }
          operatorRoutes[operator]!.add(route);
        }
      }
    }

    // Convert operator routes to the expected format
    List<Map<String, dynamic>> operators = [];
    operatorRoutes.forEach((operator, routes) {
      operators.add({'name': operator, 'routes': routes.toList()});
    });

    setState(() {
      _busSchedules = schedules;
      _busOperators = operators;
    });
  }

  String _determineStatus(List<dynamic> item) {
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
    return 'TBD';
  }

  bool _shouldIncludeSchedule(
    String timeStr,
    String status,
    DateTime manilaTime,
  ) {
    try {
      DateTime scheduledTime = _parseScheduledTime(timeStr);

      // Always include cancelled schedules regardless of time
      if (['CANCELLED', 'DELAYED', 'DEPARTED'].contains(status.toUpperCase())) {
        return true;
      }

      // For non-cancelled schedules, only include if not yet passed
      return scheduledTime.isAfter(manilaTime);
    } catch (e) {
      return true; // If we can't parse the time, include it to be safe
    }
  }

  DateTime _parseScheduledTime(String timeStr) {
    DateTime manilaTime = _currentManilaTime;

    timeStr = timeStr.trim().toUpperCase();

    bool isPM = timeStr.contains('PM');
    bool isAM = timeStr.contains('AM');

    String cleanTime = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();

    List<String> parts = cleanTime.split(':');
    if (parts.length >= 2) {
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }

      return tz.TZDateTime(
        _manilaLocation,
        manilaTime.year,
        manilaTime.month,
        manilaTime.day,
        hour,
        minute,
      );
    }

    throw FormatException('Invalid time format: $timeStr');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel the previous timer if it exists
    _debounceTimer?.cancel();

    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearching = _searchQuery.isNotEmpty;
    });

    // Only fetch data if there's a search query
    if (_searchQuery.isNotEmpty) {
      // Set up debounce timer
      _debounceTimer = Timer(Duration(milliseconds: 500), () {
        _fetchDataWithSearch();
      });
    } else {
      // Clear data when search is empty
      setState(() {
        _busOperators = [];
        _busSchedules = [];
        _errorMessage = null;
      });
    }
  }

  Future<void> _fetchDataWithSearch() async {
    if (_searchQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([_fetchSchedules(), _fetchBusOperators()]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch data: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredOperators {
    if (_searchQuery.isEmpty) return [];
    return _busOperators.where((operator) {
      bool matchesName = operator['name'].toLowerCase().contains(_searchQuery);
      bool matchesRoutes = false;
      bool matchesDestinations = false;

      // Check routes
      if (operator['routes'] is List) {
        matchesRoutes = (operator['routes'] as List).any(
          (route) => route.toString().toLowerCase().contains(_searchQuery),
        );
      }

      // Check destinations
      if (operator['destinations'] is List) {
        matchesDestinations = (operator['destinations'] as List).any(
          (destination) =>
              destination.toString().toLowerCase().contains(_searchQuery),
        );
      }

      return matchesName || matchesRoutes || matchesDestinations;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredSchedules {
    if (_searchQuery.isEmpty) return [];
    return _busSchedules.where((schedule) {
      return schedule['operator'].toLowerCase().contains(_searchQuery) ||
          schedule['route'].toLowerCase().contains(_searchQuery) ||
          schedule['time'].toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            stops: [0.0, 0.4, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // App Bar Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Search',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search operators, routes, or schedules...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Search Type Tabs (only show when searching)
                    if (_isSearching)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withOpacity(0.7),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          indicator: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: EdgeInsets.all(4),
                          splashFactory: NoSplash.splashFactory,
                          overlayColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          tabs: [
                            Tab(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.business, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Operators (${_filteredOperators.length})',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Schedules (${_filteredSchedules.length})',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Content Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: _isSearching
                      ? _buildSearchResults()
                      : _buildEmptyState(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 60),
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          SizedBox(height: 24),
          Text(
            'Search for Bus Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Start typing above to search for bus operators, routes, schedules, and more.\nResults will appear automatically as you type.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 32),
          _buildQuickSearchOptions(),
        ],
      ),
    );
  }

  Widget _buildQuickSearchOptions() {
    final quickSearches = [
      'Baguio',
      'Victory Liner',
      'Morning Schedules',
      'Bicol',
      'Genesis',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Searches',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickSearches.map((search) {
            return InkWell(
              onTap: () {
                _searchController.text = search;
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  search,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      child: TabBarView(
        controller: _tabController,
        physics: BouncingScrollPhysics(),
        children: [_buildOperatorsTab(), _buildSchedulesTab()],
      ),
    );
  }

  Widget _buildOperatorsTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading operators...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildErrorMessage(),
          ),
        ),
      );
    }

    if (_filteredOperators.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildNoResults('No operators found'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: _filteredOperators.length,
        itemBuilder: (context, index) {
          final operator = _filteredOperators[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(bottom: 16),
            child: _buildOperatorCard(operator),
          );
        },
      ),
    );
  }

  Widget _buildSchedulesTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading schedules...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildErrorMessage(),
          ),
        ),
      );
    }

    if (_filteredSchedules.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildNoResults('No schedules found'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: _filteredSchedules.length,
        itemBuilder: (context, index) {
          final schedule = _filteredSchedules[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(bottom: 16),
            child: _buildScheduleCard(schedule),
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          SizedBox(height: 16),
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _refreshData, child: Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildNoResults(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorCard(Map<String, dynamic> operator) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${operator['name']} details...')),
          );
          launchInBrowser(
            operator['website_url'] ??
                'https://www.google.com/search?q=${Uri.encodeComponent('${operator['name']}}')}',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operator['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Routes:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: operator['routes'].take(3).map<Widget>((route) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      route,
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    Color statusColor = _getStatusColor(schedule['status']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Time
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      schedule['time'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),

                  // Route Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule['route'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          schedule['operator'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      schedule['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildScheduleInfo(
                    'Gate',
                    schedule['gate'].replaceAll(RegExp(r'[^0-9]'), ''),
                    Icons.location_on,
                  ),
                  SizedBox(width: 16),
                  _buildScheduleInfo(
                    'Bay',
                    schedule['bay'].replaceAll(RegExp(r'[^0-9]'), ''),
                    Icons.local_parking,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ARRIVING':
        return Color(0xFF10B981); // Modern green
      case 'CANCELLED':
        return Color(0xFFEF4444); // Modern red
      case 'TBD':
        return Color(0xFF6B7280); // Modern gray
      case 'DELAYED':
        return Color(0xFFF59E0B); // Modern amber
      case 'DEPARTED':
        return Color(0xFF3B82F6); // Modern blue
      case 'BOARDING':
        return Color(0xFF8B5CF6); // Modern purple
      default:
        return Color(0xFF6B7280); // Default modern gray
    }
  }
}
