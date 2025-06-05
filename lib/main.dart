import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/index_page.dart'; // <-- Added IndexPage import
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/appointment_screen.dart';
import 'screens/consultant_dashboard_screen.dart';

// Add these 4:
import 'screens/book_slot_page.dart';
import 'screens/nearby_banks_page.dart';
import 'screens/previous_bookings_page.dart';
import 'screens/pending_appointments_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
      "🔔 [Background] Message: ${message.notification?.title} - ${message.notification?.body}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission();
  print('🛡️ Permission granted: ${settings.authorizationStatus}');

  String? token = await FirebaseMessaging.instance.getToken();
  print("🔑 FCM Token: $token");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          "📨 [Foreground] ${message.notification?.title} - ${message.notification?.body}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          "🟢 [Opened App] ${message.notification?.title} - ${message.notification?.body}");
    });

    return MaterialApp(
      title: 'Smart Banking App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // <-- Starting at IndexPage now
      routes: {
        '/': (context) => const IndexPage(), // <-- Changed from LoginPage
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          final userName = args?['userName'] ?? 'Guest';
          return DashboardScreen(userName: userName);
        },
        '/appointment': (context) => AppointmentScreen(),
        '/consultant_dashboard': (context) => ConsultantDashboardScreen(),

        // 🆕 Add the 4 user dashboard option routes:
        '/bookSlot': (context) => const BookSlotPage(),
        '/nearbyBanks': (context) => NearbyBanksPage(),
        '/previousBookings': (context) => const PreviousBookingsPage(),
        '/pendingAppointments': (context) => const PendingAppointmentsPage(),
      },
    );
  }
}
