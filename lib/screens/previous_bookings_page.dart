import 'package:flutter/material.dart';

class PreviousBookingsPage extends StatelessWidget {
  const PreviousBookingsPage({super.key});

  final List<Map<String, String>> dummyBookings = const [
    {
      'date': '2025-06-01',
      'time': '10:00 AM',
      'bank': 'First National Bank',
      'status': 'Completed',
    },
    {
      'date': '2025-05-28',
      'time': '2:30 PM',
      'bank': 'Standard Bank',
      'status': 'Cancelled',
    },
    {
      'date': '2025-05-20',
      'time': '9:00 AM',
      'bank': 'Capitec Bank',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Bookings'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: dummyBookings.length,
        itemBuilder: (context, index) {
          final booking = dummyBookings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                booking['status'] == 'Completed'
                    ? Icons.check_circle
                    : Icons.cancel,
                color: booking['status'] == 'Completed'
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text('${booking['bank']}'),
              subtitle: Text('Date: ${booking['date']} at ${booking['time']}'),
              trailing: Text(
                booking['status']!,
                style: TextStyle(
                  color: booking['status'] == 'Completed'
                      ? Colors.green
                      : Colors.red,
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
