import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultantDashboardScreen extends StatefulWidget {
  const ConsultantDashboardScreen({super.key});

  @override
  State<ConsultantDashboardScreen> createState() =>
      _ConsultantDashboardScreenState();
}

class _ConsultantDashboardScreenState extends State<ConsultantDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  final Stream<QuerySnapshot> _bookingsStream = FirebaseFirestore.instance
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots();

  void _updateBookingStatus(String docId, String newStatus) {
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId)
        .update({'status': newStatus});
  }

  void _deleteBooking(String docId) {
    FirebaseFirestore.instance.collection('bookings').doc(docId).delete();
  }

  void _showDetailsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['userName'] ?? 'Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${data['email']}'),
            Text('ID: ${data['idNumber']}'),
            Text('Bank: ${data['bank']}'),
            Text('Service: ${data['service']}'),
            Text('Status: ${data['status']}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<QueryDocumentSnapshot> docs, bool pendingOnly) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['userName'] ?? '').toString().toLowerCase();
      final bank = (data['bank'] ?? '').toString().toLowerCase();
      final service = (data['service'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString().toLowerCase();

      final matchesSearch = name.contains(_searchTerm) ||
          bank.contains(_searchTerm) ||
          service.contains(_searchTerm);
      final matchesStatus = pendingOnly ? status == 'pending' : true;

      return matchesSearch && matchesStatus;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
          child: Text(pendingOnly
              ? 'No pending bookings found.'
              : 'No bookings found.'));
    }

    Map<String, List<QueryDocumentSnapshot>> grouped = {
      'Today': [],
      'Tomorrow': [],
      'Upcoming': [],
      'Past': [],
    };

    for (var doc in filtered) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime bookingDate;
      if (data['dateTime'] != null && data['dateTime'] is Timestamp) {
        bookingDate = (data['dateTime'] as Timestamp).toDate();
      } else {
        bookingDate = DateTime.now();
      }

      final bookingDay =
          DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

      if (bookingDay == today) {
        grouped['Today']!.add(doc);
      } else if (bookingDay == tomorrow) {
        grouped['Tomorrow']!.add(doc);
      } else if (bookingDay.isAfter(tomorrow)) {
        grouped['Upcoming']!.add(doc);
      } else {
        grouped['Past']!.add(doc);
      }
    }

    List<Widget> listItems = [];

    grouped.forEach((category, docs) {
      if (docs.isNotEmpty) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              category,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo),
            ),
          ),
        );

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          DateTime dateTime;
          if (data['dateTime'] != null && data['dateTime'] is Timestamp) {
            dateTime = (data['dateTime'] as Timestamp).toDate();
          } else {
            dateTime = DateTime.now();
          }

          final formattedDate =
              "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
          final formattedTime =
              "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

          listItems.add(
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.account_circle, color: Colors.indigo),
                title: Text(data['userName'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank: ${data['bank'] ?? ''}'),
                    Text('Service: ${data['service'] ?? ''}'),
                    Text('Date: $formattedDate at $formattedTime'),
                  ],
                ),
                trailing: pendingOnly
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                              onPressed: () => _showDetailsDialog(data),
                              child: const Text('View Details')),
                          TextButton(
                              onPressed: () =>
                                  _updateBookingStatus(doc.id, 'Completed'),
                              child: const Text('Mark as Complete')),
                          TextButton(
                              onPressed: () =>
                                  _updateBookingStatus(doc.id, 'Cancelled'),
                              child: const Text('Reject')),
                        ],
                      )
                    : PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'View') {
                            _showDetailsDialog(data);
                          } else if (value == 'Reject') {
                            _updateBookingStatus(doc.id, 'Cancelled');
                          } else if (value == 'Complete') {
                            _updateBookingStatus(doc.id, 'Completed');
                          } else if (value == 'Delete') {
                            _deleteBooking(doc.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'View', child: Text('View Details')),
                          if (data['status']?.toString().toLowerCase() !=
                              'cancelled')
                            const PopupMenuItem(
                                value: 'Reject', child: Text('Reject')),
                          if (data['status']?.toString().toLowerCase() !=
                              'completed')
                            const PopupMenuItem(
                                value: 'Complete',
                                child: Text('Mark as Complete')),
                          const PopupMenuItem(
                              value: 'Delete', child: Text('Delete')),
                        ],
                      ),
              ),
            ),
          );
        }
      }
    });

    return ListView(children: listItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultant Dashboard'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name, bank, or service',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchTerm = '');
                  },
                ),
              ),
              onChanged: (value) {
                setState(() => _searchTerm = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _bookingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No bookings found.'));
                }
                return _buildBookingList(
                    snapshot.data!.docs, false); // Show all bookings
              },
            ),
          ),
        ],
      ),
    );
  }
}
