import 'package:flutter/material.dart';

class AppColors {
  static const Color medicalBlue = Color(0xFF0F7FAF);
  static const Color aqua = Color(0xFF44D9D9);
  static const Color accent = Color(0xFF6EE7B7);
  static const Color background = Color(0xFFF7FBFD);
  static const Color card = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF0F7FA);
  static const Color surfaceBorder = Color(0xFFE2F0F6);
  static const Color darkText = Color(0xFF062A3A);
  static const Color secondaryText = Color(0xFF1E4955);
  static const Color danger = Color(0xFFEF476F);

  // Helpers
  static const BorderRadiusGeometry corner =
      BorderRadius.all(Radius.circular(16));
}

class AppConstants {
  // Configuration app
  static const String appName = 'AVS_Saver';
  static const String appVersion = '1.0.0';

  // Collections Firestore
  static const String usersCollection = 'users';
  static const String avsCollection = 'avs';
  static const String beneficiariesCollection = 'beneficiaries';
  static const String missionsCollection = 'missions';
  static const String messagesCollection = 'messages';
  static const String bookingsCollection = 'bookings';
  static const String notificationsCollection = 'notifications';

  // Rôles canoniques (stockés en base)
  static const String roleAdmin = 'admin';
  static const String roleCoordinateur = 'coordinateur';
  static const String roleAvs = 'avs';
  static const String roleFamille = 'famille';

  // Libellés utilisateurs (UI)
  static const Map<String, String> roleLabels = {
    roleAdmin: 'Admin',
    roleCoordinateur: 'Coordinateur',
    roleAvs: 'AVS',
    roleFamille: 'Famille/Tuteur',
  };

  // Erreurs / messages
  static const String errorPermission =
      'Vous n\'avez pas la permission pour accéder à cette page.';
  static const String errorNetwork = 'Erreur de connexion réseau';
  static const String errorUnknown = 'Une erreur inattendue s\'est produite';
  static const String errorNotFound = 'Ressource non trouvée';
  static const String errorValidation = 'Données invalides';

  /// Normalise un rôle libre (depuis UI / DB) vers une valeur canonique.
  /// Gère variantes, fautes d'orthographe et labels humains.
  static String normalizeRole(String? role) {
    final r = (role ?? '').trim().toLowerCase();

    if (r.isEmpty) return roleFamille;

    // ADMIN
    if (r == roleAdmin ||
        r == 'administrator' ||
        r == 'Admin' ||
        r.contains('admin')) {
      return roleAdmin;
    }

    // COORDINATEUR
    if (r == roleCoordinateur ||
        r.contains('coord') ||
        r.contains('coordinateur') ||
        r.contains('coordon') ||
        r.contains('coordonateur') ||
        r.contains('coordonateur')) {
      return roleCoordinateur;
    }

    // AVS
    if (r == roleAvs ||
        r.contains('avs') ||
        r.contains('aux') ||
        r.contains('aide') ||
        r.contains('soin') ||
        r.contains('dipl') || // diplôme / diplo...
        r.contains('diplôm') ||
        r.contains('diplome')) {
      return roleAvs;
    }

    // FAMILLE / TUTEUR
    if (r == roleFamille ||
        r.contains('fam') ||
        r.contains('parent') ||
        r.contains('tuteur') ||
        r.contains('proche')) {
      return roleFamille;
    }

    // fallback conservateur
    return roleFamille;
  }

  // Statuts de mission
  static const String missionPending = 'pending';
  static const String missionConfirmed = 'confirmed';
  static const String missionInProgress = 'in_progress';
  static const String missionCompleted = 'completed';
  static const String missionCancelled = 'cancelled';

  // Types de notifications
  static const String notifNewBooking = 'new_booking';
  static const String notifBookingConfirmed = 'booking_confirmed';
  static const String notifBookingCancelled = 'booking_cancelled';
  static const String notifNewMessage = 'new_message';
  static const String notifMissionReminder = 'mission_reminder';

  // Limites et validations
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxBioLength = 500;
  static const double minHourlyRate = 10.0;
  static const double maxHourlyRate = 50.0;
  static const int minAge = 0;
  static const int maxAge = 120;

  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Assets
  static const String logoPath = 'assets/images/logo.jpg';
  static const String placeholderAvatar =
      'assets/images/placeholder_avatar.png';

  // Messages de succès
  static const String successAccountCreated = 'Compte créé avec succès';
  static const String successPasswordReset = 'Email de réinitialisation envoyé';
  static const String successBookingSent = 'Demande envoyée au coordinateur';
  static const String successProfileUpdated = 'Profil mis à jour';

  // Compétences AVS prédéfinies (exemples)
  static const List<String> avsSkills = [
    'Autisme',
    'Troubles DYS',
    'Déficience motrice',
    'Déficience visuelle',
    'Déficience auditive',
    'Troubles comportementaux',
  ];

  // Conditions médicales courantes (exemples)
  static const List<String> medicalConditions = [
    'Autisme',
    'Trisomie 21',
    'Paralysie cérébrale',
    'Spina bifida',
  ];

  // Durées par défaut (en minutes)
  static const int defaultSessionDuration = 60;
  static const int minSessionDuration = 30;
  static const int maxSessionDuration = 480; // 8 heures

  // Notifications push
  static const String fcmTopicAll = 'all_users';
  static const String fcmTopicAvs = 'avs_users';
  static const String fcmTopicFamilies = 'family_users';
  static const String fcmTopicCoordinators = 'coordinator_users';
}

class ApiConstants {
  // En cas d'utilisation d'API externes
  static const String baseUrl = 'https://api.avs-saver.com';
  static const Duration timeout = Duration(seconds: 30);

  // Endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String bookingsEndpoint = '/bookings';
}

class StorageConstants {
  // Clés pour le stockage local
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyFcmToken = 'fcm_token';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyOnboardingCompleted = 'onboarding_completed';
}

class RegexConstants {
  static const String email = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phone = r'^(\+237|0)[1-9](\d{8})$';
  static const String postalCode = r'^\d{5}$';
}
