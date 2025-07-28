import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

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
  String _selectedExportStatus = 'All';

  late TabController _tabController;

  final Stream<QuerySnapshot> _bookingsStream = FirebaseFirestore.instance
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  void _updateBookingStatus(String docId, String newStatus) {
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId)
        .update({'status': newStatus});
  }

  Future<void> _deleteBooking(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .delete();
    }
  }

  Future<void> _exportBookingsToPdf() async {
    final pdf = pw.Document();

    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('createdAt', descending: true);
    if (_selectedExportStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedExportStatus);
    }

    final snapshot = await query.get();

    pdf.addPage(pw.MultiPage(
      build: (context) => [
        pw.Text('Exported Bookings - Status: $_selectedExportStatus',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        ...snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Text(
              'Name: ${data['userName'] ?? ''}\n'
              'Bank: ${data['bank'] ?? ''}\n'
              'Service: ${data['service'] ?? ''}\n'
              'Email: ${data['email'] ?? ''}\n'
              'ID: ${data['idNumber'] ?? ''}\n'
              'Status: ${data['status'] ?? ''}\n'
              'DateTime: ${data['dateTime']?.toDate().toString().split('.')[0] ?? ''}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          );
        }).toList()
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  List<QueryDocumentSnapshot> _filterByStatus(
      List<QueryDocumentSnapshot> bookings, String status) {
    return status == 'All'
        ? bookings
        : bookings
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['status'] == status)
            .toList();
  }

  Widget _buildBookingList(List<QueryDocumentSnapshot> bookings, bool canEdit,
      {bool canReject = false}) {
    final filtered = bookings.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['userName']?.toLowerCase() ?? '';
      final bank = data['bank']?.toLowerCase() ?? '';
      final service = data['service']?.toLowerCase() ?? '';
      return name.contains(_searchTerm) ||
          bank.contains(_searchTerm) ||
          service.contains(_searchTerm);
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final doc = filtered[index];
        final data = doc.data() as Map<String, dynamic>;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.indigo),
            title: Text(data['userName'] ?? 'Unknown'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bank: ${data['bank']}'),
                Text('Service: ${data['service']}'),
                Text('Email: ${data['email']}'),
                Text('ID: ${data['idNumber']}'),
              ],
            ),
            trailing: canEdit
                ? DropdownButton<String>(
                    value: data['status'],
                    onChanged: (String? newValue) async {
                      if (newValue != null && newValue != data['status']) {
                        if (newValue == 'Cancelled') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Reject Booking'),
                              content: const Text(
                                  'Are you sure you want to reject this booking?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('No')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes')),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }
                        _updateBookingStatus(doc.id, newValue);
                      }
                    },
                    items: ['Pending', 'Completed', 'Cancelled'].map((value) {
                      return DropdownMenuItem<String>(
                          value: value, child: Text(value));
                    }).toList(),
                  )
                : canReject
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBooking(doc.id),
                      )
                    : null,
          ),
        );
      },
    );
  }

  Widget _buildTabContent(int index, List<QueryDocumentSnapshot> bookings) {
    switch (index) {
      case 0:
        return _buildBookingList(bookings, false);
      case 1:
        return _buildBookingList(_filterByStatus(bookings, 'Pending'), true);
      case 2:
        return _buildBookingList(bookings, true, canReject: true);
      case 3:
        return const Center(child: Text('Navigate to Book Slot page'));
      case 4:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Select which bookings to export to PDF:'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: _selectedExportStatus,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedExportStatus = newValue);
                  }
                },
                items: <String>[
                  'All',
                  'Pending',
                  'Completed',
                  'Cancelled',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _exportBookingsToPdf,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text('Export to PDF'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultant Dashboard'),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Bookings'),
            Tab(text: 'Pending Bookings'),
            Tab(text: 'Manage Bookings'),
            Tab(text: 'Book Slot'),
            Tab(text: 'Export PDF'),
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
                final bookings = snapshot.data!.docs;
                return TabBarView(
                  controller: _tabController,
                  children: List.generate(
                      5, (index) => _buildTabContent(index, bookings)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
