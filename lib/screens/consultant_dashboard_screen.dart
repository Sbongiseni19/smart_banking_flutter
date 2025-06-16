import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultantDashboardScreen extends StatefulWidget {
  const ConsultantDashboardScreen({super.key});

  @override
  State<ConsultantDashboardScreen> createState() =>
      _ConsultantDashboardScreenState();
}

class _ConsultantDashboardScreenState extends State<ConsultantDashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

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
      builder: (context) => AlertDialog(
        title: Text(data['userName'] ?? 'Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bank: ${data['bank']}'),
            Text('Service: ${data['service']}'),
            Text('Date: ${data['date']} at ${data['time']}'),
            Text('Email: ${data['email']}'),
            Text('ID: ${data['idNumber']}'),
            Text('Status: ${data['status']}'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(
      List<QueryDocumentSnapshot> docs, bool isPendingTab) {
    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['userName']?.toLowerCase() ?? '';
      final bank = data['bank']?.toLowerCase() ?? '';
      final service = data['service']?.toLowerCase() ?? '';
      final status = data['status']?.toLowerCase() ?? '';
      final matchSearch = name.contains(_searchTerm) ||
          bank.contains(_searchTerm) ||
          service.contains(_searchTerm);
      final matchTab = isPendingTab ? status == 'pending' : true;
      return matchSearch && matchTab;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No bookings found.'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final doc = filtered[index];
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'Pending';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.indigo),
            title: Text(data['userName'] ?? 'Unknown'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bank: ${data['bank']}'),
                Text('Service: ${data['service']}'),
                Text('Date: ${data['date']} at ${data['time']}'),
              ],
            ),
            trailing: isPendingTab
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'View') {
                        _showDetailsDialog(data);
                      } else if (value == 'Complete') {
                        _updateBookingStatus(doc.id, 'Completed');
                      } else if (value == 'Reject') {
                        _updateBookingStatus(doc.id, 'Cancelled');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'View', child: Text('View Details')),
                      const PopupMenuItem(
                          value: 'Complete', child: Text('Mark as Complete')),
                      const PopupMenuItem(
                          value: 'Reject', child: Text('Reject')),
                    ],
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'View') {
                        _showDetailsDialog(data);
                      } else if (value == 'Reject') {
                        _updateBookingStatus(doc.id, 'Cancelled');
                      } else if (value == 'Delete') {
                        _deleteBooking(doc.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'View', child: Text('View Details')),
                      const PopupMenuItem(
                          value: 'Reject', child: Text('Reject')),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Bookings'),
            Tab(text: 'Manage Bookings'),
          ],
        ),
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
              onChanged: (value) =>
                  setState(() => _searchTerm = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No bookings found.'));
                }

                final docs = snapshot.data!.docs;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(docs, true), // Pending
                    _buildBookingList(docs, false), // Manage All
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
