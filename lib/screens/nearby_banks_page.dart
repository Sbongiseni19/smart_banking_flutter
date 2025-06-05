import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyBanksPage extends StatelessWidget {
  final List<Map<String, String>> banks = [
    {
      'name': 'FNB Bank',
      'address': '123 Main St, Pretoria',
      'mapUrl':
          'https://www.google.com/maps/search/?api=1&query=FNB+Bank+Pretoria',
    },
    {
      'name': 'ABSA Bank',
      'address': '45 Union Ave, Pretoria',
      'mapUrl':
          'https://www.google.com/maps/search/?api=1&query=ABSA+Bank+Pretoria',
    },
    {
      'name': 'Capitec Bank',
      'address': '78 Church St, Pretoria',
      'mapUrl':
          'https://www.google.com/maps/search/?api=1&query=Capitec+Bank+Pretoria',
    },
    {
      'name': 'Standard Bank',
      'address': '21 Central Rd, Pretoria',
      'mapUrl':
          'https://www.google.com/maps/search/?api=1&query=Standard+Bank+Pretoria',
    },
  ];

  void _launchMap(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not open the map';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Banks')),
      body: ListView.builder(
        itemCount: banks.length,
        itemBuilder: (context, index) {
          final bank = banks[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(bank['name']!),
              subtitle: Text(bank['address']!),
              trailing: Icon(Icons.map),
              onTap: () => _launchMap(bank['mapUrl']!),
            ),
          );
        },
      ),
    );
  }
}
