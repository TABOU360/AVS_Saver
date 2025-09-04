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

      // Navigation selon le rôle
      switch (userProfile.role) {
        case AppConstants.roleAdmin:
          navigateTo(AppRoutes.admin);
          break;
        case AppConstants.roleCoordinateur:
          navigateTo(AppRoutes.coordinator);
          break;
        case AppConstants.roleAvs:
        case AppConstants.roleFamille:
        default:
          navigateTo(AppRoutes.home);
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

    // Définir les permissions par rôle
    switch (userProfile.role) {
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