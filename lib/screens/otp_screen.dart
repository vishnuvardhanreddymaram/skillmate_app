import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'main_navigation.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final Map<String, dynamic> signupData;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.signupData,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  
  int _timerSeconds = 60;
  Timer? _resendTimer;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerSeconds = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resendOTP() async {
    if (_timerSeconds > 0) return;
    
    setState(() => _isLoading = true);
    await _auth.verifyPhoneNumber(
      widget.phoneNumber,
      onCodeSent: (newVerificationId) {
        if (!mounted) return;
        setState(() {
          _currentVerificationId = newVerificationId;
          _isLoading = false;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP Resent!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF6C63FF),
          ),
        );
      },
      onVerificationFailed: (message) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _verifyOTP() async {
    final smsCode = otpController.text.trim();
    if (smsCode.isEmpty || smsCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _auth.signInWithOTP(_currentVerificationId, smsCode);

      if (credential != null) {
        String? error = await _auth.signUp(
          email: widget.signupData['email'],
          password: widget.signupData['password'],
          name: widget.signupData['name'],
          skillsHave: widget.signupData['skillsHave'],
          skillsWant: widget.signupData['skillsWant'],
          phone: widget.phoneNumber,
        );

        if (mounted) {
          if (error == null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigation()),
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Account Error: $error"),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains("invalid-verification-code")) {
          errorMessage = "Incorrect code. Please check and try again.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: const Color(0xFF1F2937),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 64,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Verification Code",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enter the 6-digit code sent to\n${widget.phoneNumber}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        hintText: "000000",
                        hintStyle: TextStyle(color: Colors.grey.shade300),
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _verifyOTP,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Verify Account",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: _timerSeconds == 0 ? _resendOTP : null,
                          child: Text(
                            _timerSeconds == 0 ? "Resend" : "Resend in ${_timerSeconds}s",
                            style: TextStyle(
                              color: _timerSeconds == 0 ? const Color(0xFF6C63FF) : Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
}
