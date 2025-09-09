import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../services/database_service.dart';

/// Widget qui gère automatiquement l'état d'authentification
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // En cours de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Erreur de connexion
        if (snapshot.hasError) {
          return const _ErrorScreen();
        }

        // Utilisateur connecté
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: _checkUserProfile(snapshot.data!),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (profileSnapshot.data == true) {
                return const HomeScreen(); // Profil complet
              } else {
                return const _ProfileIncompleteScreen(); // Profil à compléter
              }
            },
          );
        }

        // Utilisateur non connecté
        return const LoginScreen();
      },
    );
  }

  /// Vérifie si le profil utilisateur est complet
  Future<bool> _checkUserProfile(User user) async {
    try {
      final databaseService = DatabaseService();
      final userProfile = await databaseService.getUserProfile(user.uid);

      // Vérifier si le profil existe et est complet
      return userProfile != null &&
          userProfile.name.isNotEmpty &&
          userProfile.role.isNotEmpty;
    } catch (e) {
      print('Erreur vérification profil: $e');
      return false;
    }
  }
}

/// Écran d'erreur générique
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Veuillez redémarrer l\'application',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Forcer le rechargement de l'app
                // ou naviguer vers l'écran de login
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran affiché quand le profil est incomplet
class _ProfileIncompleteScreen extends StatelessWidget {
  const _ProfileIncompleteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                'Profil incomplet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Votre profil n\'est pas encore configuré. '
                'Veuillez compléter vos informations pour continuer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Naviguer vers l'écran de completion du profil
                    // ou vers l'inscription selon le contexte
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Compléter le profil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
