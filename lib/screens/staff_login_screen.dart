import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'take_picture_screen.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorText = '';

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email == 'staff@bank.com' && password == '1234') {
      try {
        final cameras = await availableCameras();
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TakePictureScreen(camera: frontCamera),
          ),
        );
      } catch (e) {
        setState(() {
          errorText = 'Camera error: $e';
        });
      }
    } else {
      setState(() {
        errorText = 'Invalid credentials';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADMIN LOGIN PAGE!!')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (errorText.isNotEmpty)
              Text(errorText, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Staff Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
