// lib/widgets/auth_wrapper.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/avs_dashboard_screen.dart';
import '../screens/family_dashboard_screen.dart';
import '../screens/coordinator_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/home_screen.dart';
import 'loading_widget.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final DatabaseService _db = DatabaseService();
  User? _firebaseUser;
  AppUser? _appUser;
  AuthState _authState = AuthState.checking;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);
  }

  Future<void> _handleAuthStateChange(User? firebaseUser) async {
    if (!mounted) return;

    setState(() {
      _firebaseUser = firebaseUser;
      _authState = AuthState.checking;
      _errorMessage = null;
    });

    try {
      if (firebaseUser == null) {
        setState(() {
          _appUser = null;
          _authState = AuthState.unauthenticated;
        });
        return;
      }

      final appUser = await _db.getUserProfile(firebaseUser.uid);

      if (appUser == null) {
        await _handleMissingProfile(firebaseUser);
        return;
      }

      if (!await _isAccountActive(appUser)) {
        setState(() {
          _authState = AuthState.suspended;
          _errorMessage =
              'Votre compte a été suspendu. Contactez l\'administrateur.';
        });
        return;
      }

      setState(() {
        _appUser = appUser;
        _authState = AuthState.authenticated;
      });
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'utilisateur: $e');
      setState(() {
        _authState = AuthState.error;
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
      });
    }
  }

  Future<void> _handleMissingProfile(User firebaseUser) async {
    try {
      await _db.createUserProfile(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'Utilisateur',
        role: AppConstants.roleFamille,
      );

      final appUser = await _db.getUserProfile(firebaseUser.uid);

      if (appUser != null) {
        setState(() {
          _appUser = appUser;
          _authState = AuthState.authenticated;
        });
      } else {
        throw Exception('Impossible de créer le profil utilisateur');
      }
    } catch (e) {
      debugPrint('Erreur création profil: $e');
      setState(() {
        _authState = AuthState.error;
        _errorMessage = 'Erreur lors de la création du profil: ${e.toString()}';
      });
    }
  }

  Future<bool> _isAccountActive(AppUser user) async {
    // TODO: Implémenter la vérification du statut du compte
    return true;
  }

  Future<void> _retry() async {
    setState(() {
      _authState = AuthState.checking;
      _errorMessage = null;
    });
    await _handleAuthStateChange(_firebaseUser);
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // SUPPRIMEZ MaterialApp ici - retournez directement le widget
    return _buildCurrentScreen();
  }

  Widget _buildCurrentScreen() {
    switch (_authState) {
      case AuthState.checking:
        return _buildCheckingScreen();

      case AuthState.unauthenticated:
        return const LoginScreen();

      case AuthState.authenticated:
        return _buildAuthenticatedScreen();

      case AuthState.error:
        return _buildErrorScreen();

      case AuthState.suspended:
        return _buildSuspendedScreen();

      case AuthState.needsSetup:
        return _buildSetupScreen();
    }
  }

  Widget _buildCheckingScreen() {
    return const Scaffold(
      body: Center(
        child: LoadingWidget(
          message: 'Vérification de votre connexion...',
          type: LoadingType.pulse,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildAuthenticatedScreen() {
    if (_appUser == null) {
      return _buildErrorScreen();
    }

    // Pour les rôles non reconnus ou comme écran temporaire
    return const HomeScreen();
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Erreur de connexion',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Une erreur inattendue s\'est produite.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuspendedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Compte suspendu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Votre compte a été temporairement suspendu.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Ouvrir le support ou contact
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contacter le support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings,
                size: 80,
                color: Colors.blue.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Configuration requise',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Veuillez compléter la configuration de votre compte.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigation vers écran de setup
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuer la configuration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AuthState {
  checking,
  unauthenticated,
  authenticated,
  error,
  suspended,
  needsSetup,
}
