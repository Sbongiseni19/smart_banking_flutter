import 'package:flutter/material.dart';

class ExportBookingsScreen extends StatelessWidget {
  const ExportBookingsScreen({super.key});

  void _exportData() {
    // We'll implement PDF/Excel logic later
    print('Exporting...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Bookings')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Export Bookings'),
          onPressed: _exportData,
        ),
      ),
    );
  }
}
