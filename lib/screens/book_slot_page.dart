import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final List<String> branches = [
    'Capitec - Sunnyside',
    'Standard Bank - Hatfield',
    'ABSA - Pretoria CBD',
    'FNB - Menlyn Mall',
    'Nedbank - Arcadia',
  ];

  final List<String> services = [
    'Open New Account',
    'Loan Application',
    'Card Replacement',
    'Update Personal Details',
    'Fraud Report',
  ];

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

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid, // ✅ UID stored here
        'userName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'idNumber': idController.text.trim(),
        'bank': selectedBranch,
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
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
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
