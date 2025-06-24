import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_register_screen.dart'; // <-- ✅ new OTP screen file

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

  bool _isLoading = false;

  Future<bool> _checkIfUserExists() async {
    final idNumber = _idNumberController.text.trim();
    final email = _emailController.text.trim();

    final emailSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    final idSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('idNumber', isEqualTo: idNumber)
        .get();

    return emailSnapshot.docs.isNotEmpty || idSnapshot.docs.isNotEmpty;
  }

  Future<void> _validateAndProceedToOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (await _checkIfUserExists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Email or ID number already in use.")),
      );
      setState(() => _isLoading = false);
      return;
    }

    // ✅ Go to OTP screen with all user details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPRegisterScreen(
          fullName: _fullNameController.text.trim(),
          idNumber: _idNumberController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
        ),
      ),
    );

    setState(() => _isLoading = false);
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
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Enter your name';
                    }

                    // Regex to allow letters, spaces, hyphens, and apostrophes
                    final regex = RegExp(r"^[a-zA-Z\s'-]+(?:[\s'-][a-zA-Z]+)*$");
                    if (!regex.hasMatch(val)) {
                      return 'Please enter a valid name (letters only)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _idNumberController,
                  decoration: const InputDecoration(labelText: 'ID Number'),
                validator: (val) {

                  if (val == null || val.length < 6) {
                    return 'First 6 characters are rewuired';
                  }

                  final month = int.parse(val.substring(2, 4));
                  final day = int.parse(val.substring(4, 6));
                  final year = int.parse(val.substring(0, 2));

                  if (val.isEmpty) {
                    return 'Enter a valid ID number';
                  }
                  // Check if month and day is valid  
                  if (month < 1 || month > 12 || day < 1 || day > 31) {
                    return 'Invalid month or day in ID number';    
                  }

                  
                  //Validate that The date must not be in the future
                  int? now = int.tryParse(DateTime.now().year.toString().substring(2, 4));

                  //check if year is not in the future
                  if (now != null && now < year ) {
                    return 'ID number cannot be from the future';
                  }
             

                  return null;
                }),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Enter your email';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(val)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Enter a password';
                  }

                  // Strong password policy regex
                  final regex = RegExp(r'^(?=.*?[a-z])(?=.*[A-Z])(?=.*?[0-9])(?=.*?[!@#$%^*?&()]).{8,}$');
                  if (!regex.hasMatch(val)) {
                    return 'Password must be at least 8 characters long, '
                           'include uppercase, lowercase, numbers, and special characters';
                  }
                  return null;
                }),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (val){

                    if (val == null || val.isEmpty) {
                      return 'Please re- enter your password';
                    }

                    
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  }
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration:
                      const InputDecoration(labelText: 'Phone (+27...)'),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Enter a phone number';
                    }
                  
                    // Check if phone number starts with +27 and is 10 characters long
                    if (!RegExp(r'^\+27[0-9]{9}$').hasMatch(val)) {
                      return 'Enter a valid phone number (+27 XX XXX XXXX)';
                    }
                  
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _validateAndProceedToOTP,
                        child: const Text('Register & Verify OTP'),
                      ),
              ],
                
              ),
          ),
        ),
      ),
    )
  }
}
