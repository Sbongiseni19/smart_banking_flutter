import '../services/booking_data.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart'; // ✅ Correct path for LocationService

class ConsultantDashboardScreen extends StatelessWidget {
  const ConsultantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = BookingData().appointments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: 'Get My Location',
            onPressed: () async {
              try {
                Position? position = await LocationService.getCurrentLocation();
                if (position != null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('📍 Your Location'),
                      content: Text(
                        'Latitude: ${position.latitude}\nLongitude: ${position.longitude}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('⚠️ Error'),
                    content: Text(e.toString()),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: bookings.isEmpty
          ? const Center(child: Text('No bookings available.'))
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(booking['name'] ?? ''),
                    subtitle: Text(
                        'ID: ${booking['id'] ?? ''} | Email: ${booking['email'] ?? ''}'),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Bank: ${booking['bank'] ?? ''}'),
                        Text('Service: ${booking['service'] ?? ''}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
