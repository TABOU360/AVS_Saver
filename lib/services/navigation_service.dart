import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_routes.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final DatabaseService _databaseService = DatabaseService();

  BuildContext? get currentContext => navigatorKey.currentContext;

  // Normalise un rôle/métier venant de la base en l'un des rôles attendus par l'app.
  String _normalizeRole(String role) {
    final r = role.trim().toLowerCase();

    if (r == AppConstants.roleAdmin.toLowerCase()) {
      return AppConstants.roleAdmin;
    }
    if (r == AppConstants.roleCoordinateur.toLowerCase()) {
      return AppConstants.roleCoordinateur;
    }
    if (r == AppConstants.roleAvs.toLowerCase() ||
        r.contains('avs') ||
        r.contains('aux') ||
        r.contains('aide') ||
        r.contains('soin')) {
      return AppConstants.roleAvs;
    }
    if (r == AppConstants.roleFamille.toLowerCase() ||
        r.contains('fam') ||
        r.contains('parent') ||
        r.contains('proche')) {
      return AppConstants.roleFamille;
    }

    // Rôle inconnu -> fallback vers famille (comportement permissif)
    return AppConstants.roleFamille;
  }

  /// Navigation basée sur le rôle utilisateur
  Future<void> navigateBasedOnRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      navigateToLogin();
      return;
    }

    try {
      final userProfile = await _databaseService.getUserProfile(user.uid);
      if (userProfile == null) {
        navigateToLogin();
        return;
      }

      final role = _normalizeRole(userProfile.role);

      // Navigation selon le rôle — on remplace toute la pile
      switch (role) {
        case AppConstants.roleAdmin:
          _pushNamedAndRemoveUntil(AppRoutes.admin);
          break;
        case AppConstants.roleCoordinateur:
          _pushNamedAndRemoveUntil(AppRoutes.coordinator);
          break;
        case AppConstants.roleAvs:
          _pushNamedAndRemoveUntil(AppRoutes.avsDashboard);
          break;
        case AppConstants.roleFamille:
        default:
          _pushNamedAndRemoveUntil(AppRoutes.familyDashboard);
          break;
      }
    } catch (e) {
      print('Erreur navigation basée sur rôle: $e');

      navigateToLogin();
    }
  }

  /// Navigation vers l'écran de connexion
  void navigateToLogin() {
    _pushNamedAndRemoveUntil(AppRoutes.login);
  }

  /// Navigation vers l'accueil
  void navigateToHome() {
    _pushNamedAndRemoveUntil(AppRoutes.home);
  }

  /// Navigation vers le profil
  void navigateToProfile() {
    navigateTo(AppRoutes.profile);
  }

  /// Navigation générale
  Future<void> navigateTo(String routeName, {Object? arguments}) async {
    if (await canNavigateTo(routeName)) {
      navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
    } else {
      showPermissionError();
    }
  }

  /// Navigation de remplacement avec vérification de permission
  Future<void> navigateAndReplace(String routeName, {Object? arguments}) async {
    if (await canNavigateTo(routeName)) {
      navigatorKey.currentState?.pushReplacementNamed(
        routeName,
        arguments: arguments,
      );
    } else {
      showPermissionError();
    }
  }

  /// Navigation avec suppression de la pile
  void _pushNamedAndRemoveUntil(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Retour en arrière
  void goBack([Object? result]) {
    if (navigatorKey.currentState?.canPop() == true) {
      navigatorKey.currentState?.pop(result);
    } else {
      // Si on ne peut pas pop, on redirige vers l'accueil
      navigateToHome();
    }
  }

  /// Vérifier les permissions avant navigation
  Future<bool> canNavigateTo(String routeName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userProfile = await _databaseService.getUserProfile(user.uid);
      if (userProfile == null) return false;

      final role = _normalizeRole(userProfile.role);

      // Définir les permissions par rôle
      return _isRouteAllowedForRole(routeName, role);
    } catch (e) {
      print('Erreur vérification permission: $e');

      return false;
    }
  }

  /// Vérifie si une route est autorisée pour un rôle donné
  bool _isRouteAllowedForRole(String routeName, String role) {
    final allowedRoutes = _getAllowedRoutesForRole(role);
    return allowedRoutes.contains(routeName);
  }

  /// Retourne les routes autorisées pour un rôle
  List<String> _getAllowedRoutesForRole(String role) {
    // Liste de TOUTES les routes disponibles dans l'app
    final allRoutes = [
      AppRoutes.home,
      AppRoutes.admin,
      AppRoutes.coordinator,
      AppRoutes.avsDashboard,
      AppRoutes.familyDashboard,
      AppRoutes.browseAvs,
      AppRoutes.avsProfile,
      AppRoutes.booking,
      AppRoutes.beneficiaries,
      AppRoutes.beneficiaryDetail,
      AppRoutes.agenda,
      AppRoutes.messages,
      AppRoutes.profile,
      AppRoutes.login,
      AppRoutes.register,
    ];

    switch (role) {
      case AppConstants.roleAdmin:
        return allRoutes; // ADMIN A ACCÈS À TOUT

      case AppConstants.roleCoordinateur:
        return [
          AppRoutes.home,
          AppRoutes.coordinator,
          AppRoutes.avsDashboard,
          AppRoutes.familyDashboard,
          AppRoutes.browseAvs,
          AppRoutes.avsProfile,
          AppRoutes.booking,
          AppRoutes.beneficiaries,
          AppRoutes.beneficiaryDetail,
          AppRoutes.agenda,
          AppRoutes.messages,
          AppRoutes.profile,
        ];

      case AppConstants.roleAvs:
        return [
          AppRoutes.home,
          AppRoutes.avsDashboard,
          AppRoutes.agenda,
          AppRoutes.messages,
          AppRoutes.profile,
        ];

      case AppConstants.roleFamille:
        return [
          AppRoutes.home,
          AppRoutes.familyDashboard,
          AppRoutes.browseAvs,
          AppRoutes.avsProfile,
          AppRoutes.booking,
          AppRoutes.beneficiaries,
          AppRoutes.beneficiaryDetail,
          AppRoutes.agenda,
          AppRoutes.messages,
          AppRoutes.profile,
        ];

      default:
        return [
          AppRoutes.home,
          AppRoutes.profile,
          AppRoutes.login,
        ];
    }
  }

  /// Afficher un message d'erreur de permission
  void showPermissionError() {
    final context = currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppConstants.errorPermission),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Vider toute la pile de navigation
  void clearStackAndNavigateTo(String routeName, {Object? arguments}) {
    _pushNamedAndRemoveUntil(routeName, arguments: arguments);
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> get isUserLoggedIn async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final profile = await _databaseService.getUserProfile(user.uid);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir le rôle de l'utilisateur actuel
  Future<String?> get currentUserRole async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final profile = await _databaseService.getUserProfile(user.uid);
      return profile?.role;
    } catch (e) {
      return null;
    }
  }
}
