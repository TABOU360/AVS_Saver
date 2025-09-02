import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/browse_avs_screen.dart';
import 'screens/avs_profile_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/beneficiaries_screen.dart';
import 'screens/beneficiary_detail_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/coordinator_screen.dart';
import 'screens/admin_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AVSApp());
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

class AVSApp extends StatelessWidget {
  const AVSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AVS_Saver',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.browseAvs: (_) => BrowseAvsScreen(),
        AppRoutes.avsProfile: (_) => const AvsProfileScreen(),
        AppRoutes.booking: (_) => const BookingScreen(),
        AppRoutes.beneficiaries: (_) => BeneficiariesScreen(),
        AppRoutes.beneficiaryDetail: (_) => const BeneficiaryDetailScreen(),
        AppRoutes.agenda: (_) => const AgendaScreen(),
        AppRoutes.messages: (_) => const MessagesScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.coordinator: (_) => const CoordinatorScreen(),
        AppRoutes.admin: (_) => const AdminScreen(),
      },
    );
  }
}