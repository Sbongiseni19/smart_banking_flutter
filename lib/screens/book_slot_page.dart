import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class BookSlotPage extends StatefulWidget {
  @override
  _BookSlotPageState createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  final _formKey = GlobalKey<FormState>();

  String? _userName;
  String? _userID;
  String? _userEmail;

  String? _selectedBank;
  String? _selectedBranch;

  Position? _currentPosition;

  List<String> banks = ['Capitec', 'FNB', 'Standard Bank'];
  List<String> branches = [];

  bool _loadingUser = true;
  bool _loadingBranches = false;
  bool _locationPermissionDenied = false;

  static const String googleApiKey = 'AIzaSyCgDsWsGkj8wEEzomITwJu4FzsXtb2F_lw';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _determinePosition();
  }

  Future<void> _fetchUserDetails() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _loadingUser = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? currentUser.displayName ?? '';
          _userID = data['id_number'] ?? '';
          _userEmail = data['email'] ?? currentUser.email ?? '';
          _loadingUser = false;
        });
      } else {
        setState(() {
          _userName = currentUser.displayName ?? '';
          _userID = '';
          _userEmail = currentUser.email ?? '';
          _loadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = FirebaseAuth.instance.currentUser?.displayName ?? '';
        _userID = '';
        _userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
        _loadingUser = false;
      });
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationPermissionDenied = true;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationPermissionDenied = true;
      });
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _locationPermissionDenied = true;
        });
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = pos;
      _locationPermissionDenied = false;
    });
  }

  Future<List<String>> fetchNearbyBranches(
      String bankName, double lat, double lng) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&keyword=$bankName&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;

      // Return unique branch names sorted by proximity
      List<String> fetchedBranches =
          results.map((place) => place['name'] as String).toSet().toList();
      return fetchedBranches;
    } else {
      throw Exception('Failed to fetch nearby branches');
    }
  }

  Future<void> _onBankChanged(String? bank) async {
    if (bank == null || _currentPosition == null) {
      setState(() {
        branches = [];
        _selectedBranch = null;
      });
      return;
    }

    setState(() {
      _selectedBank = bank;
      _selectedBranch = null;
      _loadingBranches = true;
      branches = [];
    });

    try {
      List<String> nearbyBranches = await fetchNearbyBranches(
          bank, _currentPosition!.latitude, _currentPosition!.longitude);

      setState(() {
        branches = nearbyBranches;
        _loadingBranches = false;
      });
    } catch (e) {
      setState(() {
        branches = [];
        _loadingBranches = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch branches: $e')));
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to book a slot.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('bookings').add({
      'userId': currentUser.uid,
      'name': _userName ?? '',
      'id_number': _userID ?? '',
      'email': _userEmail ?? '',
      'bank': _selectedBank,
      'branch': _selectedBranch,
      'status': 'pending',
      'dateTime': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking submitted successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return Scaffold(
        appBar: AppBar(title: Text('Book Banking Slot')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_locationPermissionDenied) {
      return Scaffold(
        appBar: AppBar(title: Text('Book Banking Slot')),
        body: Center(
          child: Text(
            'Location permission denied. Please enable location to find nearest branches.',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Book Banking Slot')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _userName == null
            ? Center(child: Text('User data not found'))
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _userName,
                      readOnly: true,
                      decoration: InputDecoration(labelText: 'Full Name'),
                    ),
                    TextFormField(
                      initialValue: _userID,
                      readOnly: true,
                      decoration: InputDecoration(labelText: 'ID Number'),
                    ),
                    TextFormField(
                      initialValue: _userEmail,
                      readOnly: true,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      decoration: InputDecoration(labelText: 'Select Bank'),
                      items: banks
                          .map(
                            (bank) => DropdownMenuItem(
                              value: bank,
                              child: Text(bank),
                            ),
                          )
                          .toList(),
                      onChanged: _onBankChanged,
                      validator: (value) =>
                          value == null ? 'Please select a bank' : null,
                    ),
                    SizedBox(height: 20),
                    if (_loadingBranches)
                      Center(child: CircularProgressIndicator()),
                    if (!_loadingBranches && branches.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedBranch,
                        decoration: InputDecoration(labelText: 'Select Branch'),
                        items: branches
                            .map(
                              (branch) => DropdownMenuItem(
                                value: branch,
                                child: Text(branch),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBranch = val),
                        validator: (value) =>
                            value == null ? 'Please select a branch' : null,
                      ),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submitBooking,
                      child: Text('Submit Booking'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
