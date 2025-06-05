import 'package:flutter/material.dart';

class PendingAppointmentsPage extends StatefulWidget {
  const PendingAppointmentsPage({super.key});

  @override
  State<PendingAppointmentsPage> createState() =>
      _PendingAppointmentsPageState();
}

class _PendingAppointmentsPageState extends State<PendingAppointmentsPage> {
  final List<Map<String, String>> pendingAppointments = [
    {
      'bankName': 'Capitec - Mamelodi',
      'date': '2025-06-10',
      'time': '09:00 AM',
      'status': 'Pending',
    },
    {
      'bankName': 'FNB - Menlyn',
      'date': '2025-06-12',
      'time': '11:30 AM',
      'status': 'Pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Appointments'),
        backgroundColor: Colors.indigo,
      ),
      body: pendingAppointments.isEmpty
          ? const Center(child: Text('No pending appointments.'))
          : ListView.builder(
              itemCount: pendingAppointments.length,
              itemBuilder: (context, index) {
                final appointment = pendingAppointments[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading:
                        const Icon(Icons.pending_actions, color: Colors.orange),
                    title: Text('${appointment['bankName']}'),
                    subtitle: Text(
                        'Date: ${appointment['date']} at ${appointment['time']}'),
                    trailing: Text(
                      appointment['status'] ?? '',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
