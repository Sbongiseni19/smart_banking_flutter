import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final bankController = TextEditingController();
  final serviceController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userName': nameController.text,
        'email': emailController.text,
        'idNumber': idController.text,
        'bank': bankController.text,
        'service': serviceController.text,
        'date': dateController.text,
        'time': timeController.text,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(), // Required for sorting
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Booking submitted successfully!')),
      );

      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    validator: (val) => val!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (val) => val!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: 'ID Number'),
                    validator: (val) => val!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: bankController,
                    decoration: const InputDecoration(labelText: 'Bank Branch'),
                    validator: (val) => val!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: serviceController,
                    decoration:
                        const InputDecoration(labelText: 'Service Required'),
                    validator: (val) => val!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: dateController,
                    decoration:
                        const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                    validator: (val) => val!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: timeController,
                    decoration: const InputDecoration(
                        labelText: 'Time (e.g. 09:00 AM)'),
                    validator: (val) => val!.isEmpty ? 'Required' : null),
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
