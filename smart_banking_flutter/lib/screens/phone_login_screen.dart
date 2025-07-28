import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'dart:ui' as ui; // For registering view type
import 'dart:html'; // For HTML element
import 'consultant_dashboard_screen.dart';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  late RecaptchaVerifier webRecaptchaVerifier;
  late ConfirmationResult confirmationResult;

  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Register the recaptcha container for web
    // (This tells Flutter where to render the invisible widget)
    ui_web.platformViewRegistry.registerViewFactory(
      'recaptcha-container',
      (int viewId) {
        final element = DivElement()
          ..id = 'recaptcha-container'
          ..style.width = '100%'
          ..style.height = '100px';
        return element;
      },
    );
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) throw Exception("Phone number cannot be empty");

      if (FirebaseAuth.instance is FirebaseAuthWeb) {
        webRecaptchaVerifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          container: 'recaptcha-container',
          size: RecaptchaVerifierSize.normal,
          theme: RecaptchaVerifierTheme.light,
          onSuccess: () => print('✅ reCAPTCHA passed'),
          onError: (e) => print('❌ reCAPTCHA error: $e'),
          onExpired: () => print('⚠️ reCAPTCHA expired'),
        );

        confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(
          phone,
          webRecaptchaVerifier,
        );

        setState(() {
          _otpSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ OTP sent to $phone')),
        );
      } else {
        throw Exception("Web-only authentication is being used.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to send OTP: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    try {
      final otp = _otpController.text.trim();
      if (otp.isEmpty) throw Exception("Please enter OTP");

      final userCredential = await confirmationResult.confirm(otp);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("✅ Logged in! UID: ${userCredential.user?.uid}")),
      );

      _navigateToDashboard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Invalid OTP. Try again.')),
      );
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ConsultantDashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Phone Login (Web)")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_otpSent)
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Enter phone number",
                  hintText: "+27xxxxxxxxx",
                ),
                keyboardType: TextInputType.phone,
              ),
            if (_otpSent)
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: "Enter OTP"),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _otpSent ? _verifyOTP : _sendOTP,
                    child: Text(_otpSent ? "Verify OTP" : "Send OTP"),
                  ),
            const SizedBox(height: 20),
            if (!_otpSent)
              const SizedBox(
                height: 100,
                child: HtmlElementView(viewType: 'recaptcha-container'),
              ),
          ],
        ),
      ),
    );
  }
}
