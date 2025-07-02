import 'package:flutter/material.dart';

class FAQ extends StatefulWidget {
  const FAQ({super.key});

  @override
  State<FAQ> createState() => _FAQState();
}

class _FAQState extends State<FAQ> {
  // Dummy FAQ data
  final List<Map<String, String>> faqData = [
    {
      'question': 'What is PITX?',
      'answer':
          'PITX (Parañaque Integrated Terminal Exchange) is the largest bus terminal in the Philippines, serving as a major transportation hub for buses traveling to and from various destinations in Luzon.',
    },
    {
      'question': 'What are the operating hours of PITX?',
      'answer':
          'PITX operates 24 hours a day, 7 days a week. However, individual bus operators may have different schedules, so it\'s best to check with your specific bus company for their departure times.',
    },
    {
      'question': 'How do I get to PITX?',
      'answer':
          'PITX is accessible via multiple modes of transportation:\n• By car: Take SLEX and exit at PITX\n• By bus: Take buses with "PITX" signage\n• By jeepney: Various jeepney routes pass through PITX\n• By UV Express: Several UV Express routes serve PITX',
    },
    {
      'question': 'What destinations can I reach from PITX?',
      'answer':
          'PITX serves various destinations across Luzon including:\n• Batangas and surrounding areas\n• Bicol region (Naga, Legazpi, etc.)\n• Mindoro (via Batangas port)\n• Tagaytay and Cavite\n• Some Metro Manila routes',
    },
    {
      'question': 'Is there parking available at PITX?',
      'answer':
          'Yes, PITX has multiple parking areas available for both short-term and long-term parking. Parking fees apply and rates vary depending on the duration and type of vehicle.',
    },
    {
      'question': 'Are there food options at PITX?',
      'answer':
          'Yes, PITX has various dining options including fast food chains like Jollibee, McDonald\'s, and Chowking, as well as local restaurants and convenience stores for your travel needs.',
    },
    {
      'question': 'Can I book bus tickets in advance?',
      'answer':
          'Yes, many bus operators at PITX offer advance booking. You can book tickets online through their websites or mobile apps, or visit their counters at the terminal for in-person booking.',
    },
    {
      'question': 'What facilities are available at PITX?',
      'answer':
          'PITX offers various facilities including:\n• Restrooms and shower facilities\n• ATM machines\n• Free WiFi\n• Waiting lounges\n• Information desk\n• Medical clinic\n• Prayer room\n• Baggage storage',
    },
    {
      'question': 'Is PITX accessible for persons with disabilities?',
      'answer':
          'Yes, PITX is designed to be accessible for persons with disabilities (PWDs) with features like ramps, elevators, accessible restrooms, and designated seating areas.',
    },
    {
      'question': 'How do I contact PITX for inquiries?',
      'answer':
          'You can contact PITX through:\n• Phone: (02) 8-PITX-BUS (748-9287)\n• Email: info@pitx.com.ph\n• Website: www.pitx.com.ph\n• Visit the information desk at the terminal',
    },
  ];

  // Track which FAQ items are expanded
  List<bool> expandedStates = [];

  @override
  void initState() {
    super.initState();
    // Initialize all items as collapsed
    expandedStates = List.generate(faqData.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find answers to commonly asked questions about PITX services and facilities.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            // FAQ Accordion List
            ...faqData.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> faq = entry.value;

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          expandedStates[index] = !expandedStates[index];
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq['question']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              expandedStates[index]
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: expandedStates[index] ? null : 0,
                      child: expandedStates[index]
                          ? Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                faq['answer']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            )
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 20),
            // Contact section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Still have questions?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Contact our customer service team for additional assistance.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '(02) 8-PITX-BUS (748-9287)',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'info@pitx.com.ph',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
