import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OTPRegisterScreen extends StatefulWidget {
  final String fullName;
  final String idNumber;
  final String email;
  final String password;
  final String phone;

  const OTPRegisterScreen({
    super.key,
    required this.fullName,
    required this.idNumber,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  State<OTPRegisterScreen> createState() => _OTPRegisterScreenState();
}

class _OTPRegisterScreenState extends State<OTPRegisterScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  void _startResendCooldown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 30;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Optionally use this for automatic sign-in
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ OTP failed: ${e.message}')),
        );
        setState(() => _isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
        _startResendCooldown();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyAndRegister() async {
    final code = _otpController.text.trim();
    if (_verificationId == null || code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Sign in with phone credential
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      final phoneUser =
          await FirebaseAuth.instance.signInWithCredential(phoneCredential);

      // Step 2: Link email/password to same user
      final emailCredential = EmailAuthProvider.credential(
        email: widget.email,
        password: widget.password,
      );

      await phoneUser.user!.linkWithCredential(emailCredential);

      // Step 3: Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneUser.user!.uid)
          .set({
        'fullName': widget.fullName,
        'idNumber': widget.idNumber,
        'email': widget.email,
        'phone': widget.phone,
        'uid': phoneUser.user!.uid,
      });

      // Step 4: Show success dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: const Text('✅ You have registered successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Verification or registration failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildResendButton() {
    return ElevatedButton(
      onPressed: _canResend ? _sendOTP : null,
      child: _canResend
          ? const Text('🔁 Resend OTP')
          : Text('⏳ $_resendCountdown s'),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📲 Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Enter the OTP sent to your phone',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.verified),
                    onPressed: _verifyAndRegister,
                    label: const Text('Verify & Complete Registration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
            const SizedBox(height: 20),
            _buildResendButton(),
          ],
        ),
      ),
    );
  }
}
