import 'package:flutter/material.dart';
import 'dart:async';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  bool _showSuggestions = true;

  // Quick suggestion buttons
  final List<Map<String, dynamic>> _suggestions = [
    {'text': 'Bus Schedules', 'query': 'schedule', 'icon': Icons.schedule},
    {'text': 'Operating Hours', 'query': 'hours', 'icon': Icons.access_time},
    {
      'text': 'Bus Operators',
      'query': 'operators',
      'icon': Icons.directions_bus,
    },
    {'text': 'Destinations', 'query': 'destinations', 'icon': Icons.place},
    {'text': 'Facilities', 'query': 'facilities', 'icon': Icons.business},
    {'text': 'Parking Info', 'query': 'parking', 'icon': Icons.local_parking},
    {'text': 'Food & Dining', 'query': 'food', 'icon': Icons.restaurant},
    {'text': 'How to Get There', 'query': 'location', 'icon': Icons.directions},
    {
      'text': 'Booking Tickets',
      'query': 'booking',
      'icon': Icons.confirmation_number,
    },
    {'text': 'Contact Info', 'query': 'contact', 'icon': Icons.contact_phone},
  ];

  // Predefined responses for common questions
  final Map<String, String> _responses = {
    'hello': 'Hello! Welcome to PITX. How can I help you today?',
    'hi':
        'Hi there! I\'m here to help you with information about PITX services.',
    'hours':
        'PITX operates 24 hours a day, 7 days a week. However, individual bus operators may have different schedules.',
    'schedule':
        'You can check bus schedules in our Bus Schedules section. Different operators have varying departure times throughout the day.',
    'operators':
        'PITX serves multiple bus operators including Victory Liner, Genesis, and many others. You can find the complete list in our Bus Operators section.',
    'destinations':
        'From PITX, you can reach Batangas, Bicol region, Mindoro, Tagaytay, Cavite, and other Luzon destinations.',
    'parking':
        'Yes, PITX has multiple parking areas available for both short-term and long-term parking. Parking fees apply.',
    'food':
        'PITX has various dining options including fast food chains, local restaurants, and convenience stores.',
    'facilities':
        'PITX offers restrooms, shower facilities, ATMs, free WiFi, waiting lounges, information desk, medical clinic, prayer room, and baggage storage.',
    'contact':
        'You can contact PITX at 8396-3817 to 18 or email customerservice@pitx.com.ph',
    'help':
        'I can help you with information about PITX schedules, operators, destinations, facilities, and general inquiries. What would you like to know?',
    'booking':
        'Many bus operators at PITX offer advance booking online or at their counters. Check with your specific operator for booking options.',
    'location':
        'PITX is accessible via SLEX. You can also take buses, jeepneys, or UV Express with "PITX" signage.',
    'thanks':
        'You\'re welcome! Is there anything else you\'d like to know about PITX?',
    'thank you':
        'You\'re welcome! Feel free to ask if you have any other questions.',
    'bye': 'Goodbye! Have a safe trip and thank you for using PITX services.',
    'goodbye':
        'Goodbye! Have a safe trip and thank you for using PITX services.',
  };

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimationController.repeat();

    // Add welcome message
    _addMessage(
      ChatMessage(
        text:
            'Hello! I\'m PITX Assistant. How can I help you today?\n\nTap on any of the suggestions below or type your question.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getBotResponse(String userMessage) {
    String message = userMessage.toLowerCase().trim();

    // Check for exact matches first
    if (_responses.containsKey(message)) {
      return _responses[message]!;
    }

    // Check for partial matches
    for (String key in _responses.keys) {
      if (message.contains(key)) {
        return _responses[key]!;
      }
    }

    // Check for keywords
    if (message.contains('time') ||
        message.contains('open') ||
        message.contains('close')) {
      return _responses['hours']!;
    } else if (message.contains('bus') && message.contains('schedule')) {
      return _responses['schedule']!;
    } else if (message.contains('where') || message.contains('how to get')) {
      return _responses['location']!;
    } else if (message.contains('ticket') || message.contains('book')) {
      return _responses['booking']!;
    } else if (message.contains('eat') || message.contains('restaurant')) {
      return _responses['food']!;
    } else if (message.contains('wifi') ||
        message.contains('atm') ||
        message.contains('restroom')) {
      return _responses['facilities']!;
    } else if (message.contains('help') ||
        message.contains('what can you do')) {
      // Show suggestions again when user asks for help
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showSuggestions = true;
        });
      });
      return _responses['help']!;
    }

    // Default response
    return 'I\'m sorry, I didn\'t understand that. You can ask me about PITX schedules, operators, destinations, facilities, or general information. For specific inquiries, please contact our customer service at 8396-3817 to 18.';
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Hide suggestions after first message
    if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
      });
    }

    // Add user message
    _addMessage(
      ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
    );

    _messageController.clear();

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    // Simulate bot thinking time
    Timer(Duration(milliseconds: 1000 + (message.length * 50)), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });

        // Add bot response
        _addMessage(
          ChatMessage(
            text: _getBotResponse(message),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  void _sendSuggestion(String query) {
    // Hide suggestions
    setState(() {
      _showSuggestions = false;
    });

    // Add user message
    _addMessage(
      ChatMessage(text: query, isUser: true, timestamp: DateTime.now()),
    );

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });

    // Simulate bot thinking time
    Timer(Duration(milliseconds: 1000 + (query.length * 50)), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });

        // Add bot response
        _addMessage(
          ChatMessage(
            text: _getBotResponse(query),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PITX Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Messages area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount:
                    _messages.length +
                    (_isTyping ? 1 : 0) +
                    (_showSuggestions ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_showSuggestions &&
                      index == _messages.length + (_isTyping ? 1 : 0)) {
                    return _buildSuggestionChips();
                  }
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // Input area
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.send, color: Colors.white),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Quick questions:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _sendSuggestion(suggestion['query']!),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          Theme.of(context).primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          suggestion['icon'] as IconData,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          suggestion['text']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.person, color: Colors.grey[600], size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(
                            0.5 +
                                0.5 *
                                    (((_typingAnimationController.value * 3) -
                                            i)
                                        .clamp(0, 1)),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (i < 2) SizedBox(width: 4),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
