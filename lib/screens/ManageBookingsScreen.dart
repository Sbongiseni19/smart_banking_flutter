import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_detail_screen.dart'; // Import detail screen

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  Future<void> _updateStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(id)
        .update({'status': newStatus});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking $newStatus')),
    );
  }

  Future<void> _deleteBooking(String id) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking deleted')),
    );
  }

  void _confirmAction(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    var collection =
        FirebaseFirestore.instance.collection('bookings').orderBy('dateTime');
    if (_selectedFilter == 'All') {
      return collection.snapshots();
    } else {
      return collection.where('status', isEqualTo: _selectedFilter).snapshots();
    }
  }

  List<QueryDocumentSnapshot> _filterSearch(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final service = (data['service'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || service.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        backgroundColor: Colors.indigo,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _selectedFilter,
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Pending', child: Text('Pending')),
              PopupMenuItem(value: 'Approved', child: Text('Approved')),
              PopupMenuItem(value: 'Rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or service',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // 📋 Booking List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var bookings = _filterSearch(snapshot.data!.docs);

                if (bookings.isEmpty) {
                  return Center(
                      child: Text('No $_selectedFilter bookings found.'));
                }

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    var doc = bookings[index];
                    var data = doc.data() as Map<String, dynamic>;

                    DateTime? dateTime;
                    if (data['dateTime'] != null &&
                        data['dateTime'] is Timestamp) {
                      dateTime = data['dateTime'].toDate();
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingDetailScreen(booking: data),
                            ),
                          );
                        },
                        title: Text(data['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Service: ${data['service'] ?? ''}'),
                            if (dateTime != null)
                              Text('Date: ${dateTime.toLocal()}'),
                            Text('Status: ${data['status']}'),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              tooltip: 'Approve',
                              onPressed: () => _confirmAction(
                                'Approve Booking',
                                'Are you sure you want to approve this booking?',
                                () => _updateStatus(doc.id, 'Approved'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Reject',
                              onPressed: () => _confirmAction(
                                'Reject Booking',
                                'Are you sure you want to reject this booking?',
                                () => _updateStatus(doc.id, 'Rejected'),
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.grey),
                              tooltip: 'Delete',
                              onPressed: () => _confirmAction(
                                'Delete Booking',
                                'Are you sure you want to delete this booking?',
                                () => _deleteBooking(doc.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
