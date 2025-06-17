import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> _updateBookingStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId)
        .update({'status': newStatus});
  }

  Future<void> _deleteBooking(String docId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(docId).delete();
  }

  Future<void> _exportToPdf(List<QueryDocumentSnapshot> bookings) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Table.fromTextArray(
            headers: ['Name', 'Bank', 'Service', 'Date', 'Time', 'Status'],
            data: bookings.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return [
                data['userName'] ?? '',
                data['bank'] ?? '',
                data['service'] ?? '',
                data['date'] ?? '',
                data['time'] ?? '',
                data['status'] ?? ''
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Widget _buildSearchBar(bool visible) {
    return visible
        ? Padding(
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
          )
        : const SizedBox.shrink();
  }

  Widget _buildBookingsList(Stream<QuerySnapshot> stream,
      {bool canModify = false, bool showActions = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bookings found.'));
        }

        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userName = data['userName']?.toLowerCase() ?? '';
          final bank = data['bank']?.toLowerCase() ?? '';
          final service = data['service']?.toLowerCase() ?? '';
          return userName.contains(_searchTerm) ||
              bank.contains(_searchTerm) ||
              service.contains(_searchTerm);
        }).toList();

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.account_circle,
                    color: Color.fromARGB(255, 48, 48, 51)),
                title: Text(data['userName'] ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank: ${data['bank']}'),
                    Text('Service: ${data['service']}'),
                    Text('Date: ${data['date']} at ${data['time']}'),
                    Text('Email: ${data['email']}'),
                    Text('ID: ${data['idNumber']}'),
                  ],
                ),
                trailing: showActions
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await _updateBookingStatus(doc.id, 'Completed');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Reject Booking'),
                                  content: const Text(
                                      'Are you sure you want to reject this booking?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Reject')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _updateBookingStatus(doc.id, 'Rejected');
                              }
                            },
                          ),
                        ],
                      )
                    : canModify
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Color.fromARGB(255, 38, 99, 184)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete Booking'),
                                      content: const Text(
                                          'Are you sure you want to delete this booking?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _deleteBooking(doc.id);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.orange),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Reject Booking'),
                                      content: const Text(
                                          'Are you sure you want to reject this booking?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Reject')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _updateBookingStatus(
                                        doc.id, 'Rejected');
                                  }
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultant Dashboard'),
        backgroundColor: const Color.fromARGB(255, 245, 245, 247),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Bookings'),
            Tab(text: 'Pending Bookings'),
            Tab(text: 'Manage Bookings'),
            Tab(text: 'Export PDF'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(_tabController.index != 3),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(
                  FirebaseFirestore.instance.collection('bookings').snapshots(),
                ),
                _buildBookingsList(
                  FirebaseFirestore.instance
                      .collection('bookings')
                      .where('status', isEqualTo: 'Pending')
                      .snapshots(),
                  showActions: true,
                ),
                _buildBookingsList(
                  FirebaseFirestore.instance.collection('bookings').snapshots(),
                  canModify: true,
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('No bookings to export.'));
                    }

                    return Center(
                      child: ElevatedButton(
                        onPressed: () => _exportToPdf(snapshot.data!.docs),
                        child: const Text('Export All Bookings to PDF'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
