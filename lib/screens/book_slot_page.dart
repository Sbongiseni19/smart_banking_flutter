import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookSlotPage extends StatefulWidget {
  const BookSlotPage({super.key});

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final idController = TextEditingController();

  String? selectedBranch;
  String? selectedService;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  List<String> nearestBranches = [];
  String? selectedNearestBranch;

  final List<String> branches = [
    'Capitec',
    'Standard Bank',
    'ABSA',
    'FNB',
    'Nedbank',
  ];

  final List<String> services = [
    'Open New Account',
    'Loan Application',
    'Card Replacement',
    'Update Personal Details',
    'Fraud Report',
  ];

  // Replace this with your actual Google Places API key
  final String googleApiKey = 'AIzaSyCgDsWsGkj8wEEzomITwJu4FzsXtb2F_lw';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nameController.text = data['name'] ?? '';
          idController.text = data['idNumber'] ?? '';
          emailController.text = user.email ?? '';
        });
      } else {
        // If no user doc, fill email from auth
        setState(() {
          emailController.text = user.email ?? '';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services.')),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _searchNearestBranches() async {
    if (selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank branch first.')),
      );
      return;
    }

    final position = await _determinePosition();
    if (position == null) return;

    final lat = position.latitude;
    final lng = position.longitude;

    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=$lat,$lng'
            '&radius=5000'
            '&keyword=$selectedBranch branch'
            '&key=$googleApiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List results = data['results'];
      setState(() {
        nearestBranches =
            results.map<String>((place) => place['name'] as String).toList();
        selectedNearestBranch = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch nearby branches')),
      );
    }
  }

  Future<void> _submitBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before booking.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (selectedDate == null || selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both date and time.')),
        );
        return;
      }

      if (selectedNearestBranch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the nearest branch.')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'userName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'idNumber': idController.text.trim(),
        'bank': selectedBranch,
        'nearestBranch': selectedNearestBranch,
        'service': selectedService,
        'status': 'Pending',
        'dateTime': DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Booking submitted successfully!')),
      );

      _formKey.currentState!.reset();
      setState(() {
        selectedBranch = null;
        selectedService = null;
        selectedDate = null;
        selectedTime = null;
        nearestBranches.clear();
        selectedNearestBranch = null;
      });
    }
  }

  String? _validateId(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length != 13) return 'ID must be 13 digits';
    if (!RegExp(r'^\d{13}$').hasMatch(value)) return 'ID must be numeric only';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(
          child: Text('Please log in to book an appointment.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Book Appointment'),
          backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'ID Number'),
                  keyboardType: TextInputType.number,
                  validator: _validateId,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Bank Branch'),
                  value: selectedBranch,
                  items: branches.map((branch) {
                    return DropdownMenuItem(value: branch, child: Text(branch));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedBranch = val),
                  validator: (val) =>
                      val == null ? 'Please select a branch' : null,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _searchNearestBranches,
                  child: const Text('Find Nearest Branches'),
                ),
                if (nearestBranches.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Nearest Branch'),
                    value: selectedNearestBranch,
                    items: nearestBranches.map((branchName) {
                      return DropdownMenuItem(
                        value: branchName,
                        child: Text(branchName),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => selectedNearestBranch = val),
                    validator: (val) =>
                        val == null ? 'Please select a nearest branch' : null,
                  ),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Service Required'),
                  value: selectedService,
                  items: services.map((service) {
                    return DropdownMenuItem(
                        value: service, child: Text(service));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedService = val),
                  validator: (val) =>
                      val == null ? 'Please select a service' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(selectedDate == null
                          ? 'No date selected'
                          : 'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
                    ),
                    ElevatedButton(
                        onPressed: _pickDate, child: const Text('Pick Date')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(selectedTime == null
                          ? 'No time selected'
                          : 'Time: ${selectedTime!.format(context)}'),
                    ),
                    ElevatedButton(
                        onPressed: _pickTime, child: const Text('Pick Time')),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 73, 75, 84),
                  ),
                  child: const Text('Submit Booking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
