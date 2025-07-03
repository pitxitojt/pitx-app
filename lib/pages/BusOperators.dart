import 'package:flutter/material.dart';

class BusOperators extends StatefulWidget {
  const BusOperators({super.key});

  @override
  State<BusOperators> createState() => _BusOperatorsState();
}

class _BusOperatorsState extends State<BusOperators> {
  String selectedRoute = 'Select Provincial Route';
  bool showOperators = false;

  // Dummy data for provincial routes
  final List<String> provincialRoutes = [
    'Manila to Baguio',
    'Manila to Davao',
    'Manila to Iloilo',
    'Manila to Cebu',
    'Manila to Cagayan de Oro',
    'Manila to Dumaguete',
    'Manila to Tuguegarao',
    'Manila to Legazpi',
  ];

  // Dummy data for bus operators
  final List<Map<String, dynamic>> busOperators = [
    {
      'time': '08:10',
      'endTime': '07:51',
      'destination': 'Baguio',
      'operator': 'SOLID NORTH',
      'code': 'SN951',
      'additionalInfo': 'AIR123 (+3)',
      'lastBagOn': 'Terminal 3',
      'baggage': '32',
    },
    {
      'time': '08:45',
      'endTime': '08:01',
      'destination': 'Baguio',
      'operator': 'GENESIS',
      'code': 'GEN624',
      'additionalInfo': 'EVY128 (+2)',
      'lastBagOn': 'Terminal 3',
      'baggage': '48',
    },
    {
      'time': '09:20',
      'endTime': '08:13',
      'destination': 'Baguio',
      'operator': 'VICTORY LINER',
      'code': 'VL892',
      'additionalInfo': 'VIC445 (+1)',
      'lastBagOn': 'Terminal 2',
      'baggage': '28',
    },
  ];

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
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_border, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Saved',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.4],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Quick action icons
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(Icons.luggage, 'Lost\nBaggage'),
                    _buildQuickAction(Icons.schedule, 'Duty-Free\nSchedule'),
                    _buildQuickAction(Icons.people, 'Travel\nCompanion'),
                    _buildQuickAction(
                      Icons.medical_services,
                      'Travel\nConcierge',
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
                            'FIND YOUR BUS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Theme.of(context).primaryColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Scan',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

                    // Trip type tabs
                    Container(
                      margin: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.departure_board,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Arrival',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_bus,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Departure',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Info text
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Updated at 24 Jun 2025\nTap to load earlier routes',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Bus operators list
                    if (showOperators) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Route details may change without notice. Please check again closer to the scheduled route time.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Use Column instead of Expanded ListView
                      ...busOperators
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

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
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
                'Redirecting to ${operator['operator']} booking page...',
              ),
            ),
          );
        },
        child: Column(
          children: [
            Row(
              children: [
                // Time section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operator['time'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      operator['endTime'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),

                SizedBox(width: 16),

                // Route arrow and destination
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_bus,
                            color: Theme.of(context).primaryColor,
                            size: 16,
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                              margin: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).primaryColor,
                            size: 16,
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        operator['destination'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16),

                // Operator info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        operator['operator'],
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      operator['code'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      operator['additionalInfo'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // Bottom info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Bag On',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                      Text(
                        operator['lastBagOn'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Baggage Belt',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    Text(
                      operator['baggage'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 16,
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
                      'Select Provincial Route',
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
                itemCount: provincialRoutes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(provincialRoutes[index]),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      setState(() {
                        selectedRoute = provincialRoutes[index];
                        showOperators = true;
                      });
                      Navigator.pop(context);
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
