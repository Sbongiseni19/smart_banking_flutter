import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_register_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _citizenship; // 'yes' or 'no'

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

    try {
      final userExists = await _checkIfUserExists();
      if (userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Email or ID number already in use.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      final fullName =
          '${_nameController.text.trim()} ${_surnameController.text.trim()}';
      final idOrPassport = _citizenship == 'yes'
          ? _idNumberController.text.trim()
          : 'Passport-${_passportNumberController.text.trim()}';

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPRegisterScreen(
            fullName: fullName,
            idNumber: idOrPassport,
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateIDNumber(String? value) {
    if (value == null || value.isEmpty) return 'Enter ID number';
    if (value.length != 13) return 'ID must be 13 digits';

    try {
      final dobPart = value.substring(0, 6);
      final year = int.parse(dobPart.substring(0, 2));
      final month = int.parse(dobPart.substring(2, 4));
      final day = int.parse(dobPart.substring(4, 6));

      final currentYear = DateTime.now().year;
      final fullYear = (year > currentYear % 100) ? 1900 + year : 2000 + year;

      final birthDate = DateTime(fullYear, month, day);
      if (birthDate.month != month || birthDate.day != day) {
        return 'Invalid birth date in ID';
      }

      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      if (age < 18) return 'Must be 18+ years old to register';

      return null;
    } catch (e) {
      return 'Invalid ID number format';
    }
  }

  String? _validateName(String? val) {
    if (val == null || val.trim().isEmpty) return 'This field is required';
    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(val.trim())) {
      return 'Only letters and spaces allowed';
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Password is required';
    if (val.length < 8) return 'Min 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Add uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(val)) return 'Add a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) {
      return 'Add a special character';
    }
    return null;
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _nameController.dispose();
    _surnameController.dispose();
    _idNumberController.dispose();
    _passportNumberController.dispose();
    _nationalityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _validateName,
                ),
                TextFormField(
                  controller: _surnameController,
                  decoration: const InputDecoration(labelText: 'Surname'),
                  validator: _validateName,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Are you a South African citizen?'),
                  items: const [
                    DropdownMenuItem(value: 'yes', child: Text('Yes')),
                    DropdownMenuItem(value: 'no', child: Text('No')),
                  ],
                  onChanged: (val) => setState(() => _citizenship = val),
                  validator: (val) =>
                      val == null ? 'Please select an option' : null,
                ),
                const SizedBox(height: 12),
                if (_citizenship == 'yes')
                  TextFormField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(labelText: 'ID Number'),
                    validator: _validateIDNumber,
                    keyboardType: TextInputType.number,
                  ),
                if (_citizenship == 'no') ...[
                  TextFormField(
                    controller: _passportNumberController,
                    decoration:
                        const InputDecoration(labelText: 'Passport Number'),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Enter your passport number'
                        : null,
                  ),
                  TextFormField(
                    controller: _nationalityController,
                    decoration: const InputDecoration(labelText: 'Nationality'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter nationality' : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your email' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: _validatePassword,
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
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter phone number' : null,
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
    );
  }
}
