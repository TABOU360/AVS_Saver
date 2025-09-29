import 'package:avs_saver/core/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NavigationService _navigationService = NavigationService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  AppUser? _currentAppUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) {
      _navigationService.navigateToLogin();
      return;
    }

    try {
      final userProfile =
          await _databaseService.getUserProfile(_currentUser!.uid);

      if (userProfile == null) {
        _navigationService.navigateToLogin();
        return;
      }

      setState(() {
        _currentAppUser = userProfile;
        _isLoading = false;
      });

      // Afficher un message d'accueil temporaire avant redirection
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Rediriger vers le dashboard approprié
      _redirectToDashboard(userProfile.role);
    } catch (e) {
      debugPrint('Erreur chargement profil utilisateur: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement du profil';
      });
    }
  }

  void _redirectToDashboard(String role) {
    switch (role) {
      case AppConstants.roleAvs:
        Navigator.pushReplacementNamed(context, AppRoutes.avsDashboard);
        break;
      case AppConstants.roleFamille:
        Navigator.pushReplacementNamed(context, AppRoutes.familyDashboard);
        break;
      case AppConstants.roleCoordinateur:
        Navigator.pushReplacementNamed(context, AppRoutes.coordinator);
        break;
      case AppConstants.roleAdmin:
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
        break;
      default:
        // Pour les rôles non reconnus, afficher l'écran d'erreur
        setState(() {
          _errorMessage = 'Rôle non reconnu: $role';
        });
        break;
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadUserProfile();
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _navigationService.navigateToLogin();
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
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return _buildWelcomeScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header simplifié
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chargement...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Préparation de votre espace',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Indicateur de chargement principal
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade600,
                      ),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ouverture de votre espace personnel...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentAppUser?.role ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec informations utilisateur
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _currentAppUser?.name.isNotEmpty == true
                          ? _currentAppUser!.name[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour ${_currentAppUser?.name ?? 'Utilisateur'}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getRoleDisplayName(_currentAppUser?.role ?? ''),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Message de redirection
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green.shade500,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Espace prêt !',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Redirection vers votre tableau de bord...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
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
                const Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Une erreur est survenue',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
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
                      label: const Text('Déconnexion'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.roleAvs:
        return 'auxiliaire de Vie sociale';
      case AppConstants.roleFamille:
        return 'Famille';
      case AppConstants.roleCoordinateur:
        return 'Coordinateur';
      case AppConstants.roleAdmin:
        return 'Administrateur';
      default:
        return 'Utilisateur';
    }
  }
}
