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
            .collection('bookings') // ✅ fixed collection name
            .where('status', isEqualTo: 'Pending')
            .orderBy('dateTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching appointments.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;

          if (data == null || data.docs.isEmpty) {
            return const Center(child: Text('No pending appointments.'));
          }

          return ListView.builder(
            itemCount: data.docs.length,
            itemBuilder: (context, index) {
              final doc = data.docs[index];
              final appointment = doc.data() as Map<String, dynamic>;

              final dateTime = (appointment['dateTime'] as Timestamp).toDate();
              final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
              final formattedTime = DateFormat('hh:mm a').format(dateTime);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading:
                      const Icon(Icons.pending_actions, color: Colors.orange),
                  title: Text('${appointment['bank']}'),
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
