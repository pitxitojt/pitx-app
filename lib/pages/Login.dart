import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitx/main.dart';
import 'dart:async';
import 'package:bcrypt/bcrypt.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String? _errorMessage = null;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
    _focusNodes[0].requestFocus();
  }

  bool get _isFormValid {
    for (var controller in _pinControllers) {
      if (controller.text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  void checkPin() {
    try {
      final realPin = supabase.auth.currentUser?.userMetadata?['pin'] ?? "";
      final enteredPin = _pinControllers.map((c) => c.text).join();
      print(realPin);
      print(enteredPin);
      if (BCrypt.checkpw(enteredPin, realPin)) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = "Incorrect pin. Please try again.";
        });
      }
    } catch (e) {
      setState(
        () => _errorMessage = "An error occurred while checking the pin.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with parallax effect
          Positioned.fill(
            child: Image.asset('assets/hero4.jpg', fit: BoxFit.cover),
          ),

          // Enhanced gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // Main content with animations
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  // Animated logo section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Image.asset('assets/logo.png', height: 40),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Animated main content section
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced main headline with better typography
                          Text(
                            'Your gateway to\nsafe and seamless\ntravel',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Subtitle with better contrast
                          Text(
                            'Experience convenient and reliable bus transportation with PITX',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 60),

                          // Enhanced action section
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Welcome back, ${supabase.auth.currentUser?.userMetadata?['first_name']}!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: _errorMessage == null
                                      ? const EdgeInsets.symmetric(vertical: 16)
                                      : const EdgeInsets.only(top: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      4,
                                      (index) => _buildOtpDigitField(index),
                                    ),
                                  ),
                                ),

                                // add error message if not null
                                Column(
                                  children: _errorMessage == null
                                      ? []
                                      : [
                                          Text(
                                            _errorMessage ?? "",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                ),

                                // Enhanced Continue button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isFormValid ? checkPin : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFormValid
                                          ? Colors.white
                                          : Colors.grey,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      elevation: 8,
                                      shadowColor: Colors.black.withOpacity(
                                        0.3,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Continue",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpDigitField(int index) {
    return SizedBox(
      width: 48,
      child: AspectRatio(
        aspectRatio: 0.8,
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.backspace) {
                // Handle backspace: clear current field and move to previous
                if (_pinControllers[index].text.isNotEmpty) {
                  _pinControllers[index].clear();
                  setState(() {});
                } else if (index > 0) {
                  _focusNodes[index - 1].requestFocus();
                  _pinControllers[index - 1].clear();
                  setState(() {});
                }
              }
            }
          },
          child: TextField(
            obscureText: true,
            controller: _pinControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counter: const Offstage(),
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            onTap: () {
              // Select all text when tapping on field with existing content
              if (_pinControllers[index].text.isNotEmpty) {
                _pinControllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _pinControllers[index].text.length,
                );
              }
            },
            onChanged: (value) {
              if (value.isNotEmpty && index < 3) {
                _focusNodes[index + 1].requestFocus();
              }
              // Update form validation state
              setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
