import 'dart:html';
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
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  late RecaptchaVerifier webRecaptchaVerifier;
  ConfirmationResult? confirmationResult;

  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (FirebaseAuth.instance is FirebaseAuthWeb) {
      webRecaptchaVerifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instance,
        container: 'recaptcha-container',
        size: RecaptchaVerifierSize.normal,
        theme: RecaptchaVerifierTheme.light,
        onSuccess: () => print('reCAPTCHA Completed!'),
        onError: (error) => print('reCAPTCHA Error: $error'),
        onExpired: () => print('reCAPTCHA Expired'),
      );
    }
  }

  Future<bool> _checkIfUserExists() async {
    final idNumber = _idNumberController.text.trim();
    final email = _emailController.text.trim();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    final idSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('idNumber', isEqualTo: idNumber)
        .get();

    return snapshot.docs.isNotEmpty || idSnapshot.docs.isNotEmpty;
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (await _checkIfUserExists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Email or ID number already in use.")),
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
        SnackBar(content: Text("✅ OTP sent to $phone")),
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
    if (confirmationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please send OTP first')),
      );
      return;
    }

    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final code = _otpController.text.trim();
      final phoneCredential = await confirmationResult!.confirm(code);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Create user with email and password
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

// Link phone credential if available
      final phoneAuthCredential = phoneCredential.credential;
      if (phoneAuthCredential != null) {
        await userCred.user?.linkWithCredential(phoneAuthCredential);
      }

      // Save user info in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'fullName': _fullNameController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'email': email,
        'phone': _phoneController.text.trim(),
        'uid': userCred.user!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Registration successful!')),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
        arguments: {'userName': _fullNameController.text.trim()},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Registration failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                ),
                TextFormField(
                  controller: _idNumberController,
                  decoration: const InputDecoration(labelText: 'ID Number'),
                  validator: (val) => val!.isEmpty ? 'Enter ID number' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) => val!.isEmpty ? 'Enter email' : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (val) =>
                      val != null && val.length < 6 ? 'Min 6 chars' : null,
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
                  decoration:
                      const InputDecoration(labelText: 'Phone (+27...)'),
                  validator: (val) => val!.isEmpty ? 'Enter phone' : null,
                  keyboardType: TextInputType.phone,
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
                const Text('Google reCAPTCHA must show below (web only):'),
                const SizedBox(height: 10),
                const SizedBox(
                  height: 100,
                  child: HtmlElementView(viewType: 'recaptcha-container'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
