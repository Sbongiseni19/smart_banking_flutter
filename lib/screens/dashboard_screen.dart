import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'book_slot_page.dart';
import 'nearby_banks_page.dart';
import 'previous_bookings_page.dart';
import 'pending_appointments_page.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, required this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Position? _currentPosition;
  String _currentAddress = '';
  StreamSubscription<Position>? _positionStream;

  bool _isLoading = true;
  bool _hasError = false;
  late stt.SpeechToText _speech;
  bool _isVoiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _initLocationService();
    _speech = stt.SpeechToText();
    _initVoiceAssistant();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationService() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _updateLocationState('Location services disabled', true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _updateLocationState('Location permission denied', true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _updateLocationState('Location permission permanently denied', true);
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      setState(() {
        _currentPosition = position;
        _isLoading = true;
        _hasError = false;
      });
      await _getAddressFromLatLng(position);
      _checkBankProximity(position);
    });
  }

  void _updateLocationState(String message, bool isError) {
    setState(() {
      _currentAddress = message;
      _hasError = isError;
      _isLoading = false;
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        _updateLocationState(address, false);
      } else {
        _updateLocationState(" ", true);
      }
    } catch (e) {
      _updateLocationState(" ", true);
    }
  }

  Future<void> _initVoiceAssistant() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isVoiceEnabled = true;
      });

      _speech.listen(
        onResult: (result) {
          String command = result.recognizedWords.trim().toLowerCase();
          _handleVoiceCommand(command);
        },
        listenMode: stt.ListenMode.confirmation,
      );
    } else {
      setState(() {
        _isVoiceEnabled = false;
      });
    }
  }

  void _handleVoiceCommand(String command) {
    if (command.contains("book")) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const BookSlotPage()));
    } else if (command.contains("nearby")) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => NearbyBanksPage()));
    } else if (command.contains("pending")) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PendingAppointmentsPage()));
    } else if (command.contains("history") || command.contains("previous")) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PreviousBookingsPage()));
    } else if (command.contains("logout")) {
      _showLogoutDialog();
    }
  }

  void _checkBankProximity(Position position) {
    const bankLat = -26.2041;
    const bankLng = 28.0473;

    double distance = Geolocator.distanceBetween(
        position.latitude, position.longitude, bankLat, bankLng);

    if (distance < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're near a supported bank. Need assistance?"),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${widget.userName}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Builder(
              builder: (_) {
                if (_isLoading) {
                  return const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                } else if (_hasError) {
                  return Text(
                    _currentAddress,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.redAccent),
                  );
                } else {
                  return Text(
                    _currentAddress,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w400),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          Icon(
            _isVoiceEnabled ? Icons.mic : Icons.mic_off,
            color: _isVoiceEnabled ? Colors.greenAccent : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildDashboardTile(
              icon: Icons.calendar_month,
              label: 'Book Slot',
              route: const BookSlotPage(),
            ),
            _buildDashboardTile(
              icon: Icons.location_on,
              label: 'Nearby Banks',
              route: NearbyBanksPage(),
            ),
            _buildDashboardTile(
              icon: Icons.history,
              label: 'Previous Bookings',
              route: const PreviousBookingsPage(),
            ),
            _buildDashboardTile(
              icon: Icons.pending_actions,
              label: 'Pending Appointments',
              route: const PendingAppointmentsPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required Widget route,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => route),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.indigo[50],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.indigo),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
