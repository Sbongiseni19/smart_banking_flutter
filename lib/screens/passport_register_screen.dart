import 'package:flutter/material.dart';

class PassportRegisterScreen extends StatelessWidget {
  const PassportRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Passport Registration")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Please enter your passport details below:"),
            const SizedBox(height: 20),
            TextField(
                decoration: const InputDecoration(labelText: "Full Name")),
            TextField(
                decoration:
                    const InputDecoration(labelText: "Passport Number")),
            TextField(
                decoration: const InputDecoration(labelText: "Nationality")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save passport info
              },
              child: const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}
