import 'dart:html'; // For web-only view
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  late RecaptchaVerifier webRecaptchaVerifier;
  ConfirmationResult? confirmationResult;

  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize reCAPTCHA only for web
    if (FirebaseAuth.instance is FirebaseAuthWeb) {
      webRecaptchaVerifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instance,
        container: 'recaptcha-container',
        size: RecaptchaVerifierSize.normal,
        theme: RecaptchaVerifierTheme.light,
        onSuccess: () => print('✅ reCAPTCHA Completed'),
        onError: (e) => print('❌ reCAPTCHA Error: $e'),
        onExpired: () => print('⚠️ reCAPTCHA Expired'),
      );
    }
  }

  Future<bool> _checkIfUserExists() async {
    final email = _emailController.text.trim();
    final idNumber = _idNumberController.text.trim();

    final emailExists = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    final idExists = await FirebaseFirestore.instance
        .collection('users')
        .where('idNumber', isEqualTo: idNumber)
        .get();

    return emailExists.docs.isNotEmpty || idExists.docs.isNotEmpty;
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (await _checkIfUserExists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Email or ID number already in use")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final phone = _phoneController.text.trim();

      confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(
        phone,
        webRecaptchaVerifier,
      );

      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ OTP sent to $phone')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ OTP Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTPAndRegister() async {
    setState(() => _isLoading = true);

    try {
      final otp = _otpController.text.trim();

      final userCredential = await confirmationResult!.confirm(otp);
      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': _fullNameController.text.trim(),
          'idNumber': _idNumberController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'uid': user.uid,
        });

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
          arguments: {'userName': _fullNameController.text.trim()},
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Verification failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) =>
                    val!.isEmpty ? 'Enter your full name' : null,
              ),
              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(labelText: 'ID Number'),
                validator: (val) => val!.isEmpty ? 'Enter your ID' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Password must be 6+ characters' : null,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (val) => val != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (+27...)'),
                validator: (val) => val!.isEmpty ? 'Enter phone number' : null,
              ),
              if (_otpSent)
                TextFormField(
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
                  onPressed: _verifyOTPAndRegister,
                  child: const Text('Verify OTP & Register'),
                ),
              const SizedBox(height: 20),
              const Text('reCAPTCHA must appear below (web only):'),
              const SizedBox(height: 10),
              const SizedBox(
                height: 100,
                child: HtmlElementView(viewType: 'recaptcha-container'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
