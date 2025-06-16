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
  bool _showPendingOnly = true; // Toggle between Pending / Manage bookings view

  final Stream<QuerySnapshot> _bookingsStream = FirebaseFirestore.instance
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots();

  void _updateBookingStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId)
        .update({'status': newStatus});
  }

  void _deleteBooking(String docId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(docId).delete();
  }

  void _showDetailsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
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

        return AlertDialog(
          title: Text('Booking Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Name: ${data['userName'] ?? 'N/A'}'),
                Text('Email: ${data['email'] ?? 'N/A'}'),
                Text('ID Number: ${data['idNumber'] ?? 'N/A'}'),
                Text('Bank: ${data['bank'] ?? 'N/A'}'),
                Text('Service: ${data['service'] ?? 'N/A'}'),
                Text('Date: $formattedDate'),
                Text('Time: $formattedTime'),
                Text('Status: ${data['status'] ?? 'N/A'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  Widget _buildBookingList(List<QueryDocumentSnapshot> docs, bool pendingOnly) {
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

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final doc = filtered[index];
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

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        child: const Text('View Details'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _updateBookingStatus(doc.id, 'Completed'),
                        child: const Text('Mark as Complete'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _updateBookingStatus(doc.id, 'Cancelled'),
                        child: const Text('Reject'),
                      ),
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
                            value: 'Complete', child: Text('Mark as Complete')),
                      const PopupMenuItem(
                          value: 'Delete', child: Text('Delete')),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultant Dashboard'),
        backgroundColor: Colors.indigo,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showPendingOnly = !_showPendingOnly;
              });
            },
            child: Text(
              _showPendingOnly ? 'Manage Bookings' : 'Pending Bookings',
              style: const TextStyle(color: Colors.white),
            ),
          )
        ],
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
                  return Center(
                      child: Text(_showPendingOnly
                          ? 'No pending bookings found.'
                          : 'No bookings found.'));
                }

                return _buildBookingList(snapshot.data!.docs, _showPendingOnly);
              },
            ),
          ),
        ],
      ),
    );
  }
}
