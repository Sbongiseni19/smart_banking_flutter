import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyBanksPage extends StatefulWidget {
  const NearbyBanksPage({Key? key}) : super(key: key);

  @override
  State<NearbyBanksPage> createState() => _NearbyBanksPageState();
}

class _NearbyBanksPageState extends State<NearbyBanksPage> {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  // List of banks to choose from
  final List<String> _bankOptions = [
    'Capitec Bank',
    'FNB Bank',
    'ABSA Bank',
    'Standard Bank',
    'Nedbank',
  ];

  String? _selectedBank;

  @override
  void initState() {
    super.initState();
    _selectedBank = _bankOptions[0];
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Location services are disabled.';
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error = 'Location permissions are permanently denied.';
        _isLoading = false;
      });
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _error = 'Location permission denied.';
          _isLoading = false;
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }

  void _launchNearbyBanksMap() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    if (_selectedBank == null || _selectedBank!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank')),
      );
      return;
    }

    final latitude = _currentPosition!.latitude;
    final longitude = _currentPosition!.longitude;

    // Replace spaces with + for URL encoding bank name
    final bankQuery = Uri.encodeComponent(_selectedBank!);

    final mapUrl =
        'https://www.google.com/maps/search/?api=1&query=$bankQuery&center=$latitude,$longitude';

    final Uri uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Banks')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Select Bank to search nearby:',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedBank,
                        items: _bankOptions
                            .map((bank) => DropdownMenuItem<String>(
                                  value: bank,
                                  child: Text(bank),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBank = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _launchNearbyBanksMap,
                        icon: const Icon(Icons.map),
                        label: const Text('Show Nearby Banks on Map'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
