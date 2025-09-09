import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'services/background_handler.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
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
import 'screens/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    await _initializeServices();

    runApp(const AVSApp());
  } catch (e) {
    print('Erreur initialisation app: $e');
    runApp(const ErrorApp());
  }
}

Future<void> _initializeServices() async {
  try {
    await NotificationService().initialize();
    print('✓ NotificationService initialisé');
  } catch (e) {
    print('⚠️ Erreur initialisation services: $e');
  }
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
      themeMode: ThemeMode.system,
      navigatorKey: NavigationService().navigatorKey,
      home: const SplashScreen(),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
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
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const NotFoundScreen()),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(
              // ignore: deprecated_member_use
              MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.15))),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

/// App d'erreur affichée en cas d'échec d'initialisation
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AVS_Saver - Erreur',
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 24),
              Text(
                'Erreur d\'initialisation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Impossible de démarrer l'application.\nVeuillez redémarrer.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran pour les routes non trouvées
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page introuvable'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Page introuvable',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'La page que vous recherchez n\'existe pas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                NavigationService().navigateToHome();
              },
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\'accueil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
