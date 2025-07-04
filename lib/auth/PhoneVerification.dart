import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitx/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class PhoneVerification extends StatefulWidget {
  final String phoneNumber;
  const PhoneVerification({super.key, required this.phoneNumber});

  @override
  State<PhoneVerification> createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isVerifying = false;
  String? _errorMessage;
  late final String number = '+63${widget.phoneNumber}';

  // Timer variables
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _sendOtp();
    _startResendTimer(); // Always start timer regardless of OTP success/failure
    _focusNodes[0].requestFocus();
  }

  void _startResendTimer() {
    // Cancel existing timer if any
    _resendTimer?.cancel();

    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    try {
      // Send OTP
      await supabase.auth.signInWithOtp(phone: number);
    } catch (e) {
      print("OTP sending failed: $e");
      // Show demo message when OTP is disabled
    }
    // Note: Timer is now started in initState() to ensure it always runs
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isFormValid {
    for (var controller in _otpControllers) {
      if (controller.text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final enteredOtp = _otpControllers.map((c) => c.text).join();

    try {
      final AuthResponse res = await supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: enteredOtp,
        phone: number,
      );

      if (res.user != null) {
        setState(() {
          _isVerifying = false;
        });
        AuthManager.setLoggedIn(true);
        await _checkProfileAndNavigate();
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Invalid verification code. Please try again.';
        });
      }
    } catch (e) {
      print("OTP verification error: $e");
      setState(() {
        _isVerifying = false;
        _errorMessage =
            'Failed to verify OTP. Please resend code and try again.';
      });
    }
  }

  Future<void> _checkProfileAndNavigate() async {
    try {
      // Get current user data
      final user = supabase.auth.currentUser;
      if (user != null) {
        final userData = user.userMetadata;
        print("User metadata: $userData");

        // Check if user has required profile information
        final firstName = userData?['first_name'];
        final lastName = userData?['last_name'];
        final dateOfBirth = userData?['date_of_birth'];
        final pin = userData?['pin'];

        bool hasCompleteProfile =
            firstName != null &&
            firstName.toString().isNotEmpty &&
            lastName != null &&
            lastName.toString().isNotEmpty &&
            dateOfBirth != null &&
            dateOfBirth.toString().isNotEmpty &&
            pin != null &&
            pin.toString().isNotEmpty;

        if (hasCompleteProfile) {
          // User has complete profile, go to home page
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else {
          // User needs to complete profile
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/profile-completion',
            (route) => false,
          );
        }
      } else {
        // No user found, go to profile completion as fallback
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/profile-completion',
          (route) => false,
        );
      }
    } catch (e) {
      print("Error checking profile: $e");
      // In case of error, default to profile completion
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/profile-completion',
        (route) => false,
      );
    }
  }

  void _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    await _sendOtp();
    _startResendTimer(); // Restart the timer after resending

    setState(() {
      _isVerifying = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verification code resent!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Header text
                    const Text(
                      'Phone Verification',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the 6-digit verification code sent to',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form section with card design
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 300,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // OTP input fields
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => _buildOtpDigitField(index),
                      ),
                    ),
                  ),

                  // Error message (if any)
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isVerifying || !_isFormValid
                          ? null
                          : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300],
                        foregroundColor: _isFormValid
                            ? Colors.white
                            : Colors.grey[500],
                        elevation: _isFormValid ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Verify",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Resend code option
                  Center(
                    child: GestureDetector(
                      onTap: _canResend ? _resendCode : null,
                      child: Text(
                        _canResend
                            ? 'Resend Code'
                            : 'Resend Code in ${_resendCountdown}s',
                        style: TextStyle(
                          fontSize: 14,
                          color: _canResend
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Code delivery explanation
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'The verification code will be valid for 10 minutes',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
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
                if (_otpControllers[index].text.isNotEmpty) {
                  _otpControllers[index].clear();
                  setState(() {});
                } else if (index > 0) {
                  _focusNodes[index - 1].requestFocus();
                  _otpControllers[index - 1].clear();
                  setState(() {});
                }
              }
            }
          },
          child: TextField(
            controller: _otpControllers[index],
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
              if (_otpControllers[index].text.isNotEmpty) {
                _otpControllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _otpControllers[index].text.length,
                );
              }
            },
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
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
