import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // import the screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Banking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // <-- set login screen as the start
      routes: {
        // Add your other routes here
        '/home': (context) =>
            const MyHomePage(title: 'Home'), // example home page
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Welcome to Smart Banking Home!'),
      ),
    );
  }
}
