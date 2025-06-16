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
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  final Stream<QuerySnapshot> _bookingsStream = FirebaseFirestore.instance
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Booking Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${data['userName'] ?? ''}'),
              Text('Bank: ${data['bank'] ?? ''}'),
              Text('Service: ${data['service'] ?? ''}'),
              Text('Date: ${data['date'] ?? ''} at ${data['time'] ?? ''}'),
              Text('Email: ${data['email'] ?? ''}'),
              Text('ID Number: ${data['idNumber'] ?? ''}'),
              Text('Status: ${data['status'] ?? ''}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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
      return const Center(child: Text('No bookings found.'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final doc = filtered[index];
        final data = doc.data() as Map<String, dynamic>;

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
                Text('Date: ${data['date'] ?? ''} at ${data['time'] ?? ''}'),
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
                            _updateBookingStatus(doc.id, 'completed'),
                        child: const Text('Mark as Complete'),
                      ),
                      TextButton(
                        onPressed: () =>
                            _updateBookingStatus(doc.id, 'cancelled'),
                        child: const Text('Reject'),
                      ),
                    ],
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'View') {
                        _showDetailsDialog(data);
                      } else if (value == 'Reject') {
                        _updateBookingStatus(doc.id, 'cancelled');
                      } else if (value == 'Complete') {
                        _updateBookingStatus(doc.id, 'completed');
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
            padding: const EdgeInsets.all(12),
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
                final docs = snapshot.data!.docs;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Pending bookings tab
                    _buildBookingList(docs, true),
                    // Manage bookings tab (all bookings)
                    _buildBookingList(docs, false),
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
