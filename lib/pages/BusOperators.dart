import 'package:flutter/material.dart';
import 'package:pitx/main.dart';
import 'package:pitx/pages/WebViewPage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BusOperators extends StatefulWidget {
  const BusOperators({super.key});

  @override
  State<BusOperators> createState() => _BusOperatorsState();
}

class _BusOperatorsState extends State<BusOperators> {
  String selectedRoute = 'Select Destination';
  bool showOperators = false;

  bool _isLoading = false;
  // Dummy data for provincial routes
  // Dummy data for bus operators
  List<Map<String, dynamic>> busOperators = [];
  List<Map<String, dynamic>> filteredBusOperators = [];

  List<Map<String, dynamic>> destinations = [];

  // Search and filter variables
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedOperatorFilter = 'All Operators';
  String selectedRouteFilter = 'All Routes';
  List<String> availableOperators = ['All Operators'];
  List<String> availableRoutes = ['All Routes'];

  @override
  void initState() {
    super.initState();
    // You can initialize or manipulate busOperators here if needed
    getDestinations();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      filteredBusOperators = busOperators.where((operator) {
        bool matchesSearch = true;
        bool matchesOperator = true;
        bool matchesRoute = true;

        // Search filter
        if (searchQuery.isNotEmpty) {
          String operatorName =
              operator['bus_operators']['name']?.toLowerCase() ?? '';
          String routeName = operator['routes']['name']?.toLowerCase() ?? '';
          matchesSearch =
              operatorName.contains(searchQuery) ||
              routeName.contains(searchQuery);
        }

        // Operator filter
        if (selectedOperatorFilter != 'All Operators') {
          matchesOperator =
              operator['bus_operators']['name'] == selectedOperatorFilter;
        }

        // Route filter
        if (selectedRouteFilter != 'All Routes') {
          matchesRoute = operator['routes']['name'] == selectedRouteFilter;
        }

        return matchesSearch && matchesOperator && matchesRoute;
      }).toList();
    });
  }

  void _updateAvailableFilters() {
    Set<String> operators = {'All Operators'};
    Set<String> routes = {'All Routes'};

    for (var operator in busOperators) {
      operators.add(operator['bus_operators']['name'] ?? '');
      routes.add(operator['routes']['name'] ?? '');
    }

    setState(() {
      availableOperators = operators.toList()..sort();
      availableRoutes = routes.toList()..sort();
    });
  }

  Future<void> getDestinations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await supabase
          .from('destination')
          .select()
          .order('name', ascending: true);
      print("destinations: ");
      print(response);
      setState(() {
        destinations = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching destinations: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getRoutes() async {
    setState(() => _isLoading = true);
    try {
      // Step 1: Get all route IDs where destination = selectedRoute
      final List routeRows = await supabase
          .from('routes')
          .select('id, destination')
          .eq('destination', selectedRoute)
          .order('name', ascending: true);

      final List<int> sortedRouteIds = routeRows
          .map((r) => r['id'] as int)
          .toList();

      // Step 2: Get operator routes that match those route IDs
      final List operatorRoutes = await supabase
          .from('bus_operator_routes')
          .select('routes(id, name), bus_operators(name, website_url)')
          .inFilter('route_id', sortedRouteIds);

      operatorRoutes.sort((a, b) {
        // First, sort by route ID (to maintain route order)
        int routeComparison = sortedRouteIds
            .indexOf(a['routes']['id'])
            .compareTo(sortedRouteIds.indexOf(b['routes']['id']));

        // If routes are the same, sort by bus operator name alphabetically
        if (routeComparison == 0) {
          String operatorA = a['bus_operators']['name'] ?? '';
          String operatorB = b['bus_operators']['name'] ?? '';
          return operatorA.compareTo(operatorB);
        }

        return routeComparison;
      });
      setState(() {
        busOperators = List<Map<String, dynamic>>.from(operatorRoutes);
        filteredBusOperators = List<Map<String, dynamic>>.from(operatorRoutes);
      });
      _updateAvailableFilters();
      _applyFilters();
    } catch (e) {
      print('Error fetching routes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      searchController.clear();
      searchQuery = '';
      selectedOperatorFilter = 'All Operators';
      selectedRouteFilter = 'All Routes';
    });
    _applyFilters();
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
          'Bus Operators',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header text centered with styled container
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        "Bus Routes",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Find Your Journey',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Explore available bus operators and routes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Find your bus section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Find Your Bus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Route selection
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => _showRouteSelection(context),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Today',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    selectedRoute,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    // Search and Filter Section (only show when operators are available)
                    if (showOperators) ...[
                      SizedBox(height: 16),

                      // Search Bar
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search operators or routes...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      searchController.clear();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Filter Row
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedOperatorFilter,
                                    hint: Text('Filter by Operator'),
                                    isExpanded: true,
                                    items: availableOperators.map((
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
                                        selectedOperatorFilter = newValue!;
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
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRouteFilter,
                                    hint: Text('Filter by Route'),
                                    isExpanded: true,
                                    items: availableRoutes.map((String value) {
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
                                        selectedRouteFilter = newValue!;
                                      });
                                      _applyFilters();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8),

                      // Filter Results Count and Reset Button
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${filteredBusOperators.length} of ${busOperators.length} results',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (searchQuery.isNotEmpty ||
                                selectedOperatorFilter != 'All Operators' ||
                                selectedRouteFilter != 'All Routes')
                              TextButton(
                                onPressed: _resetFilters,
                                child: Text(
                                  'Clear Filters',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Info text
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Updated as of ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Bus operators list
                    if (showOperators) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Route details may change without notice.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Use Column instead of Expanded ListView
                      ...filteredBusOperators
                          .map(
                            (operator) => Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: _buildOperatorCard(operator),
                            ),
                          )
                          .toList(),
                      SizedBox(height: 20), // Add bottom spacing
                    ] else ...[
                      Container(
                        height:
                            200, // Give it a fixed height instead of Expanded
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Select a provincial route to view\navailable bus operators',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20), // Add bottom spacing
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildOperatorCard(Map<String, dynamic> operator) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to operator's website
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Redirecting to ${operator['bus_operators']['name']} booking page...',
              ),
            ),
          );

          launchInBrowser(
            operator['bus_operators']['website_url'] ??
                'https://www.google.com/search?q=${Uri.encodeComponent('${operator['bus_operators']['name']} PITX to ${operator['routes']['name']}')}',
          );

          // webview to website
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => WebViewPage(
          //       url:
          //           operator['bus_operators']['website_url'] ??
          //           Uri.https('google.com', '/search', {
          //             'q':
          //                 '${operator['bus_operators']['name']} PITX to ${operator['routes']['name']}',
          //           }).toString(),
          //       title: operator['bus_operators']['name'],
          //     ),
          //   ),
          // );
        },
        child: Row(
          children: [
            // Route section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${operator['routes']['name']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 16),

            // Operator section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Operator',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    operator['bus_operators']['name'],
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRouteSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Destination',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  if (_isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                  return ListTile(
                    title: Text(destinations[index]['name']),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      setState(() {
                        selectedRoute = destinations[index]['name'];
                        showOperators = true;
                      });
                      Navigator.pop(context);
                      await getRoutes();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
