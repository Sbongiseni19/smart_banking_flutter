import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/booking_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String selectedBank = 'FNB';
  String selectedService = 'Account Opening';
  String selectedBranch = '';

  final List<String> banks = ['FNB', 'ABSA', 'Standard Bank', 'Capitec'];
  final List<String> services = [
    'Account Opening',
    'Loan Inquiry',
    'Card Replacement'
  ];

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<List<String>> fetchNearbyBranches(String bank, Position pos) async {
    const apiKey =
        'AIzaSyCgDsWsGkj8wEEzomITwJu4FzsXtb2F_lw'; // Replace with your actual API key
    final keyword = Uri.encodeComponent('$bank branch');
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${pos.latitude},${pos.longitude}&radius=5000&keyword=$keyword&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['results'] != null) {
      return (data['results'] as List)
          .map((place) => place['name'].toString())
          .toList();
    } else {
      return [];
    }
  }

  void _showNearbyBranches() async {
    try {
      final pos = await _getCurrentLocation();
      final branches = await fetchNearbyBranches(selectedBank, pos);

      if (branches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No nearby branches found.')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: branches.map((branch) {
            return ListTile(
              title: Text(branch),
              onTap: () {
                setState(() {
                  selectedBranch = branch;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final booking = {
        'name': nameController.text.trim(),
        'id': idController.text.trim(),
        'email': emailController.text.trim(),
        'bank': selectedBank,
        'service': selectedService,
        'branch': selectedBranch,
      };

      BookingData().addBooking(booking);

      print('Appointment booked: $booking');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment booked successfully!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book an Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID Number'),
                validator: (value) => value!.isEmpty ? 'Enter your ID' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField(
                value: selectedBank,
                items: banks.map((bank) {
                  return DropdownMenuItem(value: bank, child: Text(bank));
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedBank = value.toString());
                },
                decoration: const InputDecoration(labelText: 'Select Bank'),
              ),
              DropdownButtonFormField(
                value: selectedService,
                items: services.map((service) {
                  return DropdownMenuItem(value: service, child: Text(service));
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedService = value.toString());
                },
                decoration: const InputDecoration(labelText: 'Select Service'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showNearbyBranches,
                child: const Text('Choose Nearby Branch'),
              ),
              const SizedBox(height: 10),
              if (selectedBranch.isNotEmpty)
                Text('Selected Branch: $selectedBranch'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
