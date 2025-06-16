import 'dart:async';
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

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();

  String? _maskedPhone;
  String? _realPhone;
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;

  bool _canResend = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _initiatePhoneVerification();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
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

  Future<void> _initiatePhoneVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Please login first.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (user.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('❌ No phone number linked to this account.')),
      );
      return;
    }

    _realPhone = user.phoneNumber;
    _maskedPhone = _realPhone!.replaceRange(
      0,
      _realPhone!.length - 3,
      '*' * (_realPhone!.length - 3),
    );

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _realPhone!,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-complete
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
          _startResendCooldown(); // Start countdown
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error sending OTP: $e')),
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

  Widget buildAnimatedResendButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _canResend ? 1.0 : 0.8, end: _canResend ? 1.0 : 0.8),
      duration: const Duration(milliseconds: 400),
      builder: (context, scale, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (!_canResend)
              SizedBox(
                width: 55,
                height: 55,
                child: CircularProgressIndicator(
                  value: (30 - _resendCountdown) / 30,
                  backgroundColor: Colors.grey.shade300,
                  strokeWidth: 4,
                  color: Colors.blue,
                ),
              ),
            Transform.scale(
              scale: scale,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canResend ? Colors.blue : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: _canResend ? _initiatePhoneVerification : null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _canResend
                      ? const Text('🔁 Resend OTP', key: ValueKey('resend_btn'))
                      : Text(
                          '⏳ $_resendCountdown s',
                          key: ValueKey('count_$_resendCountdown'),
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📲 Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_codeSent)
              const Text(
                'Sending OTP to your registered phone...',
                style: TextStyle(fontSize: 16),
              )
            else ...[
              Text(
                'OTP sent to: $_maskedPhone',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.verified),
                onPressed: _isLoading ? null : _submitCode,
                label: const Text('Verify Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 25),
              buildAnimatedResendButton(),
              const SizedBox(height: 10),
              const Text(
                'A cool animation during countdown!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 32),
            if (kIsWeb)
              const Text('reCAPTCHA will appear automatically below ⬇'),
            if (_isLoading)
              const SizedBox(height: 24, child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
