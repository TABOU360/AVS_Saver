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

    if (r == AppConstants.roleAdmin.toLowerCase())
      return AppConstants.roleAdmin;
    if (r == AppConstants.roleCoordinateur.toLowerCase())
      return AppConstants.roleCoordinateur;
    if (r == AppConstants.roleAvs.toLowerCase() ||
        r.contains('avs') ||
        r.contains('aux')) {
      return AppConstants.roleAvs;
    }
    if (r == AppConstants.roleFamille.toLowerCase() || r.contains('fam'))
      return AppConstants.roleFamille;

    // Rôle inconnu -> fallback : permettre l'accès à l'accueil (comportement plus permissif)
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
      // Navigation selon le rôle — on remplace toute la pile pour éviter conflits/doublons
      switch (role) {
        case AppConstants.roleAdmin:
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil(AppRoutes.admin, (route) => false);
          break;
        case AppConstants.roleCoordinateur:
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.coordinator, (route) => false);
          break;
        case AppConstants.roleAvs:
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.avsDashboard, (route) => false);
          break;
        case AppConstants.roleFamille:
        default:
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.familyDashboard, (route) => false);
          break;
      }
    } catch (e) {
      print('Erreur navigation: $e');
      navigateToLogin();
    }
  }

  /// Navigation vers l'écran de connexion
  void navigateToLogin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Navigation vers l'accueil
  void navigateToHome() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  /// Navigation générale
  void navigateTo(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  /// Navigation de remplacement
  void navigateAndReplace(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Retour en arrière
  void goBack([Object? result]) {
    if (navigatorKey.currentState?.canPop() == true) {
      navigatorKey.currentState?.pop(result);
    }
  }

  /// Vérifier les permissions avant navigation
  Future<bool> canNavigateTo(String routeName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userProfile = await _databaseService.getUserProfile(user.uid);
    if (userProfile == null) return false;

    final role = _normalizeRole(userProfile.role);
    // Définir les permissions par rôle
    switch (role) {
      case AppConstants.roleAdmin:
        return true; // Admin peut tout voir

      case AppConstants.roleCoordinateur:
        return ![AppRoutes.admin].contains(routeName);

      case AppConstants.roleAvs:
        return [
          AppRoutes.home,
          AppRoutes.agenda,
          AppRoutes.messages,
          AppRoutes.profile,
        ].contains(routeName);

      case AppConstants.roleFamille:
        return [
          AppRoutes.home,
          AppRoutes.browseAvs,
          AppRoutes.avsProfile,
          AppRoutes.booking,
          AppRoutes.beneficiaries,
          AppRoutes.beneficiaryDetail,
          AppRoutes.agenda,
          AppRoutes.messages,
          AppRoutes.profile,
        ].contains(routeName);

      default:
        return false;
    }
  }

  /// Afficher un message d'erreur de permission
  void showPermissionError() {
    final context = currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.errorPermission),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
