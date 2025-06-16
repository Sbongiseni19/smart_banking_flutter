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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Group bookings by `date`
  Map<String, List<QueryDocumentSnapshot>> _groupByDate(
      List<QueryDocumentSnapshot> docs) {
    Map<String, List<QueryDocumentSnapshot>> grouped = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = data['date'] ?? 'Unknown';
      grouped.putIfAbsent(date, () => []).add(doc);
    }
    return grouped;
  }

  Future<void> _cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Booking cancelled')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Appointments'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'Pending')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching appointments.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No pending appointments.'));
          }

          final groupedDocs = _groupByDate(docs);

          return ListView(
            children: groupedDocs.entries.map((entry) {
              final date = entry.key;
              final bookings = entry.value;

              final formattedDate =
                  DateFormat('MMMM dd, yyyy').format(DateTime.parse(date));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.indigo.shade100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...bookings.map((doc) {
                    final booking = doc.data() as Map<String, dynamic>;
                    final time = booking['time'] ?? 'Unknown';
                    final bank = booking['bank'] ?? 'Unknown';

                    return Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _cancelBooking(doc.id),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.pending_actions,
                              color: Colors.orange),
                          title: Text(bank),
                          subtitle: Text('Time: $time'),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _cancelBooking(doc.id),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
