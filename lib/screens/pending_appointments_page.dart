import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PendingAppointmentsPage extends StatefulWidget {
  const PendingAppointmentsPage({super.key});

  @override
  State<PendingAppointmentsPage> createState() =>
      _PendingAppointmentsPageState();
}

class _PendingAppointmentsPageState extends State<PendingAppointmentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Appointments'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Snapshot error: ${snapshot.error}');
            return const Center(child: Text('Error fetching appointments.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;

          if (data == null || data.docs.isEmpty) {
            return const Center(child: Text('No pending appointments.'));
          }

          // Parse and sort documents by combined DateTime from 'date' and 'time'
          final docsWithDateTime = data.docs
              .map((doc) {
                final appointment = doc.data() as Map<String, dynamic>;

                // Parse date string (e.g., "2025-06-19")
                final dateParts = appointment['date']?.split('-');
                if (dateParts == null || dateParts.length != 3) {
                  return null; // invalid date format
                }

                final year = int.tryParse(dateParts[0]) ?? 0;
                final month = int.tryParse(dateParts[1]) ?? 0;
                final day = int.tryParse(dateParts[2]) ?? 0;

                // Parse time string (e.g., "5:20 AM")
                final timeString = appointment['time'] ?? '12:00 AM';
                DateTime parsedTime;
                try {
                  parsedTime = DateFormat.jm().parse(timeString);
                } catch (_) {
                  parsedTime = DateTime(0); // fallback
                }

                // Combine date and time into one DateTime object
                final combinedDateTime = DateTime(
                  year,
                  month,
                  day,
                  parsedTime.hour,
                  parsedTime.minute,
                );

                return {'doc': doc, 'dateTime': combinedDateTime};
              })
              .whereType<Map<String, dynamic>>()
              .toList();

          // Sort ascending by combined DateTime
          docsWithDateTime
              .sort((a, b) => a['dateTime'].compareTo(b['dateTime']));

          return ListView.builder(
            itemCount: docsWithDateTime.length,
            itemBuilder: (context, index) {
              final doc =
                  docsWithDateTime[index]['doc'] as QueryDocumentSnapshot;
              final appointment = doc.data() as Map<String, dynamic>;
              final dateTime = docsWithDateTime[index]['dateTime'] as DateTime;

              final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
              final formattedTime = DateFormat('hh:mm a').format(dateTime);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading:
                      const Icon(Icons.pending_actions, color: Colors.orange),
                  title: Text('${appointment['bank'] ?? 'No bank info'}'),
                  subtitle: Text('Date: $formattedDate at $formattedTime'),
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
          );
        },
      ),
    );
  }
}
