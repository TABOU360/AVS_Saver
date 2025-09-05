import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'services/Background_handler.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'widgets/auth_wrapper.dart';
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
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  try {
    // 1. Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Configurer les notifications en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Initialiser les services
    await _initializeServices();

    runApp(const AVSApp());
  } catch (e) {
    print('Erreur initialisation app: $e');
    runApp(const ErrorApp());
  }
}

/// Initialiser tous les services de l'application
Future<void> _initializeServices() async {
  try {
    // Service de notifications
    await NotificationService().initialize();
    print('✓ NotificationService initialisé');

    // Autres services peuvent être initialisés ici
    print('✓ Tous les services initialisés');
  } catch (e) {
    print('⚠️ Erreur initialisation services: $e');
    // L'app continue même si certains services échouent
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

      // Navigation service pour la navigation globale
      navigatorKey: NavigationService().navigatorKey,

      // Utiliser AuthWrapper au lieu de navigation directe
      home: const AuthWrapper(),

      // Routes définies mais l'AuthWrapper gère la navigation principale
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


      // Gestion des routes inconnues
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
      },

      // Builder pour gérer les erreurs globales
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
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
                'Impossible de démarrer l\'application.\nVeuillez redémarrer.',
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