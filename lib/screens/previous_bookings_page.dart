import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PreviousBookingsPage extends StatefulWidget {
  const PreviousBookingsPage({super.key});

  @override
  State<PreviousBookingsPage> createState() => _PreviousBookingsPageState();
}

class _PreviousBookingsPageState extends State<PreviousBookingsPage> {
  String selectedFilter = 'All';
  String searchQuery = '';

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by bank or service...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedFilter == 'All',
                      onSelected: (_) => setState(() => selectedFilter = 'All'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Pending'),
                      selected: selectedFilter == 'Pending',
                      onSelected: (_) =>
                          setState(() => selectedFilter = 'Pending'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: selectedFilter == 'Completed',
                      onSelected: (_) =>
                          setState(() => selectedFilter = 'Completed'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Cancelled'),
                      selected: selectedFilter == 'Cancelled',
                      onSelected: (_) =>
                          setState(() => selectedFilter = 'Cancelled'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUser.uid)
            //.snapshots(),
            // Uncomment below line and comment above line to test without filtering by userId
            //.snapshots(),
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading bookings: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          // Debug prints - check your console/logcat for output
          print('Fetched ${docs.length} bookings');
          for (var doc in docs) {
            print('Booking document data: ${doc.data()}');
          }

          final bookings = docs
              .map((doc) {
                final booking = doc.data() as Map<String, dynamic>;
                final status = (booking['status'] ?? 'pending').toLowerCase();

                try {
                  final dateParts = (booking['date'] ?? '').split('-');
                  final year = int.tryParse(dateParts[0]) ?? 0;
                  final month = int.tryParse(dateParts[1]) ?? 1;
                  final day = int.tryParse(dateParts[2]) ?? 1;

                  final timeStr = booking['time'] ?? '12:00 AM';
                  final time = DateFormat.jm().parse(timeStr);

                  final combined =
                      DateTime(year, month, day, time.hour, time.minute);
                  return {
                    'data': booking,
                    'dateTime': combined,
                  };
                } catch (e) {
                  print('Date parsing error: $e');
                  return null;
                }
              })
              .whereType<Map<String, dynamic>>()
              .toList();

          bookings.sort((a, b) => b['dateTime'].compareTo(a['dateTime']));

          final filtered = bookings.where((item) {
            final data = item['data'] as Map<String, dynamic>;
            final status = (data['status'] ?? '').toLowerCase();
            final bank = (data['bank'] ?? '').toLowerCase();
            final service = (data['service'] ?? '').toLowerCase();

            final matchesFilter = selectedFilter == 'All' ||
                selectedFilter.toLowerCase() == status;
            final matchesSearch =
                bank.contains(searchQuery) || service.contains(searchQuery);

            return matchesFilter && matchesSearch;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final booking = filtered[index]['data'] as Map<String, dynamic>;
              final dateTime = filtered[index]['dateTime'] as DateTime;
              final status = (booking['status'] ?? 'pending').toLowerCase();

              final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
              final formattedTime = DateFormat('hh:mm a').format(dateTime);

              IconData icon;
              Color color;

              switch (status) {
                case 'completed':
                  icon = Icons.check_circle;
                  color = Colors.green;
                  break;
                case 'cancelled':
                  icon = Icons.cancel;
                  color = Colors.red;
                  break;
                default:
                  icon = Icons.pending_actions;
                  color = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(icon, color: color),
                  title: Text('${booking['bank']}'),
                  subtitle: Text(
                    'Service: ${booking['service']}\nDate: $formattedDate at $formattedTime',
                  ),
                  trailing: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
