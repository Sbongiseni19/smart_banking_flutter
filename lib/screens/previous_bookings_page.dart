import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PreviousBookingsPage extends StatelessWidget {
  const PreviousBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your bookings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Bookings'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: currentUser.uid)
            .where('status', whereIn: ['completed', 'cancelled'])
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading bookings.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No previous bookings found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final booking = docs[index].data() as Map<String, dynamic>;

              final status = booking['status'];
              final dateTime = DateTime.parse(booking['dateTime']);
              final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
              final formattedTime = DateFormat('hh:mm a').format(dateTime);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    status == 'completed' ? Icons.check_circle : Icons.cancel,
                    color: status == 'completed' ? Colors.green : Colors.red,
                  ),
                  title: Text('${booking['bank']}'),
                  subtitle: Text('Date: $formattedDate at $formattedTime'),
                  trailing: Text(
                    status,
                    style: TextStyle(
                      color: status == 'completed' ? Colors.green : Colors.red,
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
