import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String? _maskedPhone;
  String? _realPhone;
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;

  Future<void> _fetchPhoneAndSendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the current user by re-authenticating with email (if not already signed in)
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'No user found for that email.');
      }

      // Try getting user from current session
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email != email) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first with this email.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (user.phoneNumber == null) {
        throw FirebaseAuthException(
            code: 'no-phone',
            message: 'No phone number linked to this account.');
      }

      _realPhone = user.phoneNumber;
      _maskedPhone = _realPhone!.replaceRange(
          0, _realPhone!.length - 3, '*' * (_realPhone!.length - 3));

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _realPhone!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Skip auto verify on web
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (_verificationId == null || code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final credential = auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      final user = auth.FirebaseAuth.instance.currentUser;

      if (user != null) {
        if (user.phoneNumber == null) {
          await user.linkWithCredential(credential);
        } else {
          await user.reauthenticateWithCredential(credential);
        }
      } else {
        await auth.FirebaseAuth.instance.signInWithCredential(credential);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Phone Verified!')),
      );

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to verify code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_codeSent) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Enter your email',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchPhoneAndSendOTP,
                child: const Text('Send OTP to Linked Phone'),
              ),
            ] else ...[
              Text(
                'OTP sent to: $_maskedPhone',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Enter SMS Code',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitCode,
                child: const Text('Verify Code'),
              ),
            ],
            const SizedBox(height: 32),
            if (kIsWeb) const Text('reCAPTCHA will appear automatically ↓'),
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
