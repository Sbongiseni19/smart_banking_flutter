import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SelectBranchPage extends StatefulWidget {
  final String bankName;
  SelectBranchPage({required this.bankName});

  @override
  _SelectBranchPageState createState() => _SelectBranchPageState();
}

class _SelectBranchPageState extends State<SelectBranchPage> {
  List<String> nearbyBranches = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => loading = true);
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Dummy data for now
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      nearbyBranches = [
        '${widget.bankName} - Branch 1 (2km)',
        '${widget.bankName} - Branch 2 (3.5km)',
        '${widget.bankName} - Branch 3 (5km)',
      ];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Branch')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: nearbyBranches.length,
              itemBuilder: (_, index) {
                return ListTile(
                  title: Text(nearbyBranches[index]),
                  onTap: () => Navigator.pop(context, nearbyBranches[index]),
                );
              },
            ),
    );
  }
}
