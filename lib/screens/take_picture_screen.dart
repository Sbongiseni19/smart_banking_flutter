import 'dart:io' show File; // For mobile platforms only
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'consultant_screen.dart';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  const TakePictureScreen({super.key, required this.camera});

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    setState(() => isProcessing = true);

    try {
      await _initializeControllerFuture;

      final XFile imageFile = await _controller.takePicture();

      String imageUrl;

      if (kIsWeb) {
        // For Web: read bytes and upload using putData()
        final Uint8List bytes = await imageFile.readAsBytes();
        final fileName = path.basename(imageFile.name);
        final storageRef = FirebaseStorage.instance.ref().child(
            "staff_logins/${DateTime.now().millisecondsSinceEpoch}_$fileName");

        await storageRef.putData(bytes);
        imageUrl = await storageRef.getDownloadURL();
      } else {
        // For Mobile: use File and putFile()
        final File image = File(imageFile.path);
        final fileName = path.basename(image.path);
        final storageRef = FirebaseStorage.instance.ref().child(
            "staff_logins/${DateTime.now().millisecondsSinceEpoch}_$fileName");

        await storageRef.putFile(image);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('staff_logins').add({
        'image_url': imageUrl,
        'timestamp': Timestamp.now(),
        'email': 'staff@bank.com', // Replace with actual email if dynamic
      });

      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ConsultantDashboardScreen(),
        ),
      );
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a Photo to Confirm')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(child: CameraPreview(_controller)),
                ElevatedButton(
                  onPressed: isProcessing ? null : _takePicture,
                  child: isProcessing
                      ? const CircularProgressIndicator()
                      : const Text('Capture & Upload'),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
