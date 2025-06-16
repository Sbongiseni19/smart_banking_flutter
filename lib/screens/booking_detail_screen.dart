import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateTime =
        booking['dateTime'] != null && booking['dateTime'] is Timestamp
            ? (booking['dateTime'] as Timestamp).toDate()
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                _detailRow('Name', booking['name']),
                _detailRow('Email', booking['email']),
                _detailRow('Service', booking['service']),
                if (dateTime != null)
                  _detailRow('Date & Time', dateTime.toString()),
                _detailRow('Status', booking['status']),
                _detailRow('Bank', booking['bank']),
                // Add more fields as needed
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: Text(value ?? 'N/A', style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
