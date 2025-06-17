import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingAppointmentsPage extends StatefulWidget {
  const PendingAppointmentsPage({super.key});

  @override
  State<PendingAppointmentsPage> createState() =>
      _PendingAppointmentsPageState();
}

class _PendingAppointmentsPageState extends State<PendingAppointmentsPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view appointments.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pending Appointments'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'Pending')
            .where('userId', isEqualTo: user!.uid) // ✅ Filter by user
            .orderBy('dateTime') // ✅ Sort by dateTime
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
            return const Center(
                child: Text('You have no pending appointments.'));
          }

          // Group appointments by day
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in data.docs) {
            final appointment = doc.data() as Map<String, dynamic>;
            final dateTime = (appointment['dateTime'] as Timestamp?)?.toDate();

            if (dateTime == null) continue;

            final dayKey = DateFormat('EEEE, MMMM d, y').format(dateTime);

            grouped[dayKey] = grouped[dayKey] ?? [];
            grouped[dayKey]!.add({
              'docId': doc.id,
              'data': appointment,
              'dateTime': dateTime,
            });
          }

          final sortedGroupKeys = grouped.keys.toList()
            ..sort((a, b) {
              final da = DateFormat('EEEE, MMMM d, y').parse(a);
              final db = DateFormat('EEEE, MMMM d, y').parse(b);
              return da.compareTo(db);
            });

          return ListView.builder(
            itemCount: sortedGroupKeys.length,
            itemBuilder: (context, groupIndex) {
              final day = sortedGroupKeys[groupIndex];
              final bookings = grouped[day]!;

              bookings.sort((a, b) => a['dateTime'].compareTo(b['dateTime']));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.indigo.shade100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...bookings.map((booking) {
                    final appointment = booking['data'] as Map<String, dynamic>;
                    final docId = booking['docId'];
                    final dt = booking['dateTime'] as DateTime;
                    final formattedTime = DateFormat('hh:mm a').format(dt);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.pending_actions,
                            color: Colors.orange),
                        title: Text('${appointment['bank']}'),
                        subtitle:
                            Text('${appointment['service']} — $formattedTime'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cancel Booking'),
                                content: const Text(
                                    'Are you sure you want to cancel this booking?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(docId)
                                  .delete();
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
