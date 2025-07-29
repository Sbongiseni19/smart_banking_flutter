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

// Web-specific reCAPTCHA registration
import 'web_view_registry_stub.dart'
    if (dart.library.html) 'web_view_registry_web.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
      "🔔 [Background] ${message.notification?.title} - ${message.notification?.body}");
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

  if (kIsWeb) {
    registerReCAPTCHAContainer();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      print(
          "📨 [Foreground] ${message.notification?.title} - ${message.notification?.body}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print(
          "🟢 [Opened App] ${message.notification?.title} - ${message.notification?.body}");
    });

    return MaterialApp(
      title: 'Smart Banking App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const IndexPage());
          case '/login':
            return MaterialPageRoute(builder: (_) => LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => RegisterScreen());
          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final userName = args['userName'] ?? 'Guest';
            return MaterialPageRoute(
              builder: (_) => DashboardScreen(userName: userName),
            );
          case '/appointment':
            return MaterialPageRoute(builder: (_) => const AppointmentScreen());
          case '/consultant_dashboard':
            return MaterialPageRoute(
                builder: (_) => const ConsultantDashboardScreen());
          case '/verifyPhone':
            return MaterialPageRoute(
                builder: (_) => const PhoneVerificationScreen());
          case '/bookSlot':
            return MaterialPageRoute(builder: (_) => BookSlotPage());
          case '/nearbyBanks':
            return MaterialPageRoute(builder: (_) => NearbyBanksPage());
          case '/previousBookings':
            return MaterialPageRoute(
                builder: (_) => const PreviousBookingsPage());
          case '/pendingAppointments':
            return MaterialPageRoute(
                builder: (_) => const PendingAppointmentsPage());
          case '/resetPassword':
            return MaterialPageRoute(
                builder: (_) => const ResetPasswordScreen());
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('404 - Page Not Found')),
              ),
            );
        }
      },
    );
  }
}
