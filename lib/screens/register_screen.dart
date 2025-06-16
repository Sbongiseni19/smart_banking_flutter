import 'dart:html'; // Required for HtmlElementView on web
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  late RecaptchaVerifier webRecaptchaVerifier;
  late ConfirmationResult confirmationResult;

  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize reCAPTCHA verifier (for Web)
    if (FirebaseAuth.instance is FirebaseAuthWeb) {
      webRecaptchaVerifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instance, // ✅ FIXED: required 'auth'
        container: 'recaptcha-container', // Match index.html div
        size: RecaptchaVerifierSize.normal,
        theme: RecaptchaVerifierTheme.light,
        onSuccess: () => print('✅ reCAPTCHA Completed!'),
        onError: (error) => print('❌ reCAPTCHA Error: $error'),
        onExpired: () => print('⚠️ reCAPTCHA Expired'),
      );
    }
  }

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) throw Exception("Phone number cannot be empty");

      confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(
        phone,
        webRecaptchaVerifier,
      );

      setState(() => _otpSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ OTP sent to $phone")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to send OTP: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);

    try {
      final otp = _otpController.text.trim();
      if (otp.isEmpty) throw Exception("Please enter the OTP");

      final userCredential = await confirmationResult.confirm(otp);
      final user = userCredential.user;

      if (user != null) {
        // ✅ Save extra user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'phone': user.phoneNumber,
          'name': _nameController.text.trim(),
          'id_number': _idController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Registered! UID: ${user.uid}")),
        );

        Navigator.pushNamed(context, '/dashboard', arguments: {
          'userName': _nameController.text,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ OTP verification failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'ID Number'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+27XXXXXXXXX',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            if (_otpSent)
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (!_otpSent)
              ElevatedButton(
                onPressed: _sendOTP,
                child: const Text('Send OTP'),
              )
            else
              ElevatedButton(
                onPressed: _verifyOTP,
                child: const Text('Verify & Register'),
              ),
            const SizedBox(height: 20),
            // Placeholder for reCAPTCHA
            const Text("reCAPTCHA (Web Only):"),
            const SizedBox(height: 10),
            if (FirebaseAuth.instance is FirebaseAuthWeb)
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
