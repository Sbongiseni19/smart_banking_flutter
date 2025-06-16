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
            return const Center(child: Text('Error fetching appointments.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;

          if (data == null || data.docs.isEmpty) {
            return const Center(child: Text('No pending appointments.'));
          }

          // Parse & group by day
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in data.docs) {
            final appointment = doc.data() as Map<String, dynamic>;

            // Parse date & time
            final dateParts = (appointment['date'] ?? '').split('-');
            if (dateParts.length != 3) continue;

            final year = int.tryParse(dateParts[0]) ?? 0;
            final month = int.tryParse(dateParts[1]) ?? 1;
            final day = int.tryParse(dateParts[2]) ?? 1;

            DateTime timeParsed;
            try {
              timeParsed =
                  DateFormat.jm().parse(appointment['time'] ?? '12:00 AM');
            } catch (_) {
              timeParsed = DateTime(0);
            }

            final fullDateTime =
                DateTime(year, month, day, timeParsed.hour, timeParsed.minute);

            final dayKey = DateFormat('EEEE, MMMM d, y').format(fullDateTime);

            grouped[dayKey] = grouped[dayKey] ?? [];
            grouped[dayKey]!.add({
              'docId': doc.id,
              'data': appointment,
              'dateTime': fullDateTime,
            });
          }

          // Sort groups by date
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

              // Sort bookings within the group
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
