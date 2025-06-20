import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/index_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/appointment_screen.dart';
import 'screens/consultant_dashboard_screen.dart';
import 'screens/phone_verification_screen.dart';
import 'screens/book_slot_page.dart';
import 'screens/nearby_banks_page.dart';
import 'screens/previous_bookings_page.dart';
import 'screens/pending_appointments_page.dart';
import 'screens/reset_password_screen.dart';

/// Only import these for web (to use `platformViewRegistry` and `DivElement`)
/// This block avoids runtime crashes on mobile
/// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:ui_web' as ui;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
      "🔔 [Background] Message: ${message.notification?.title} - ${message.notification?.body}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permission
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission();
  print('🛡️ Permission granted: ${settings.authorizationStatus}');

  // Get FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  print("🔑 FCM Token: $token");

  // ✅ Register reCAPTCHA container for web
  if (kIsWeb) {
    ui.platformViewRegistry.registerViewFactory(
      'recaptcha-container',
      (int viewId) => html.DivElement()..id = 'recaptcha-container',
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      initialRoute: '/',
      routes: {
        '/': (context) => const IndexPage(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          final userName = args?['userName'] ?? 'Guest';
          return DashboardScreen(userName: userName);
        },
        '/appointment': (context) => const AppointmentScreen(),
        '/consultant_dashboard': (context) => const ConsultantDashboardScreen(),
        '/verifyPhone': (context) => const PhoneVerificationScreen(),
        '/bookSlot': (context) => const BookSlotPage(),
        '/nearbyBanks': (context) => NearbyBanksPage(),
        '/previousBookings': (context) => const PreviousBookingsPage(),
        '/pendingAppointments': (context) => const PendingAppointmentsPage(),
        '/phoneVerification': (context) => const PhoneVerificationScreen(),
        '/resetPassword': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
