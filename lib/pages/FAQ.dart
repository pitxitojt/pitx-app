import 'package:flutter/material.dart';

class FAQ extends StatefulWidget {
  const FAQ({super.key});

  @override
  State<FAQ> createState() => _FAQState();
}

class _FAQState extends State<FAQ> with TickerProviderStateMixin {
  // Dummy FAQ data
  final List<Map<String, String>> faqData = [
    {
      'question': 'What is PITX?',
      'answer':
          'Paranaque Integrated Terminal Exchange (PITX) is a modern transport hub that connects commuters from the South to the different cities of Metro Manila. As the first integrated and multi-modal terminal in the country, it also provides interconnectivity between different transport modes and services to ensure efficient and seamless travel for the riding public.',
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
          'Yes, PITX has various dining options including fast food chains, as well as local restaurants and convenience stores for your travel needs.',
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
          'You can contact PITX through:\n• Phone: 8396-3817 to 18\n• Email: customerservice@pitx.com.ph\n• Website: www.pitx.ph\n• Visit the information desk at the terminal',
    },
  ];

  // Track which FAQ items are expanded
  List<bool> expandedStates = [];

  // Animation controllers for smooth transitions
  List<AnimationController> animationControllers = [];
  List<Animation<double>> animations = [];

  @override
  void initState() {
    super.initState();
    // Initialize all items as collapsed
    expandedStates = List.generate(faqData.length, (index) => false);

    // Initialize animation controllers for each FAQ item
    animationControllers = List.generate(
      faqData.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    // Initialize animations with curves
    animations = animationControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);
    }).toList();
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (var controller in animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'FAQ',
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
                        "Help & Support",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Frequently Asked Questions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Find answers to commonly asked questions about PITX services and facilities',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // FAQ content section
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
                      // Modern FAQ Accordion List
                      ...faqData.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> faq = entry.value;

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
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    expandedStates[index] =
                                        !expandedStates[index];
                                    if (expandedStates[index]) {
                                      animationControllers[index].forward();
                                    } else {
                                      animationControllers[index].reverse();
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.help_outline,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
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
                                      AnimatedBuilder(
                                        animation: animations[index],
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle:
                                                animations[index].value *
                                                3.14159, // 180 degrees in radians
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: expandedStates[index]
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: expandedStates[index]
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                                size: 20,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizeTransition(
                                sizeFactor: animations[index],
                                child: FadeTransition(
                                  opacity: animations[index],
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.fromLTRB(
                                      20,
                                      16,
                                      20,
                                      20,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: AnimatedBuilder(
                                      animation: animations[index],
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            0,
                                            (1 - animations[index].value) * 10,
                                          ),
                                          child: Text(
                                            faq['answer']!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                              height: 1.5,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      SizedBox(height: 32),
                      // Modern contact section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
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
                                    ).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.support_agent,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Still have questions?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Contact our customer service team for additional assistance.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.phone,
                                          size: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        '8396-3817 to 18',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.email,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'customerservice@pitx.com.ph',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
