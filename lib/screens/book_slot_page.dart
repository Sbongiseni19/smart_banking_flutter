import 'package:flutter/material.dart';

class BookSlotPage extends StatefulWidget {
  const BookSlotPage({super.key});

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedBank;
  String? _selectedService;
  DateTime? _selectedDateTime;

  final List<String> _banks = [
    'FNB',
    'ABSA',
    'Standard Bank',
    'Capitec',
    'Nedbank'
  ];
  final List<String> _services = [
    'Open Account',
    'Loan Application',
    'Card Replacement',
    'Deposit Assistance'
  ];

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        _selectedBank != null &&
        _selectedService != null &&
        _selectedDateTime != null) {
      // TODO: Save booking to database
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking Submitted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID Number'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBank,
                hint: const Text('Select Bank'),
                items: _banks.map((bank) {
                  return DropdownMenuItem(value: bank, child: Text(bank));
                }).toList(),
                onChanged: (value) => setState(() => _selectedBank = value),
                validator: (value) =>
                    value == null ? 'Please select a bank' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedService,
                hint: const Text('Select Service'),
                items: _services.map((service) {
                  return DropdownMenuItem(value: service, child: Text(service));
                }).toList(),
                onChanged: (value) => setState(() => _selectedService = value),
                validator: (value) =>
                    value == null ? 'Please select a service' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_selectedDateTime == null
                    ? 'Pick Appointment Date & Time'
                    : 'Selected: ${_selectedDateTime.toString()}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
