import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> signupData;
  final String prefilledPhone;

  const PhoneVerificationScreen({
    super.key,
    required this.signupData,
    required this.prefilledPhone,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  late TextEditingController phoneController;
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: widget.prefilledPhone);
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    if (digits.length == 10) return '+91$digits';
    return digits;
  }

  void _verifyPhone() async {
    String phone = _formatPhoneNumber(phoneController.text.trim());
    
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(
              verificationId: verificationId,
              signupData: widget.signupData,
              phoneNumber: phone,
            ),
          ),
        );
      },
      onVerificationFailed: (message) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        String displayError = message;
        if (message.contains("missing-client-identifier")) {
          displayError = "Config Error: SHA keys or authorized domains missing in Firebase Console.";
        } else if (message.contains("invalid-phone-number")) {
          displayError = "The phone number entered is invalid. Please use +91 format.";
        } else if (message.contains("too-many-requests") || message.contains("quota-exceeded")) {
          displayError = "Daily limit exceeded or too many attempts. Please try again later.";
        } else if (message.contains("operation-not-allowed")) {
          displayError = "Phone Sign-in is not enabled in your Firebase Console.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayError),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("OTP Troubleshooting"),
        content: const Text(
          "1. Ensure you have a stable internet connection.\n"
          "2. Check if your phone number starts with +91 (for India).\n"
          "3. If using an Emulator, you must add your phone number as a 'Test Number' in Firebase Console.\n"
          "4. Ensure SHA-1 and SHA-256 fingerprints are added to Firebase Project Settings."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
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
                        Icons.phonelink_ring_rounded,
                        size: 64,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Verify your Phone",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We'll send a 6-digit code to verify your account.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
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
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF6C63FF)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      onPressed: _isLoading ? null : _verifyPhone,
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
                              "Get OTP",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: _showHelpDialog,
                      child: Text(
                        "Not getting OTP? Tap for help",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
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
}
