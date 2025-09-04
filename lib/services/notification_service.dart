import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/browser.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _requestPermissions();

      await _initializeLocalNotifications();

      await _initializeFirebaseMessaging();

      _handleForegroundMessages();

      _isInitialized = true;
      print('NotificationService initialisé avec succès');
    } catch (e) {
      print('Erreur initialisation notifications: $e');
    }
  }

  /// Demander les permissions de notifications
  Future<void> _requestPermissions() async {

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permissions notifications: ${settings.authorizationStatus}');

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Obtenir le token FCM
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en premier plan: ${message.notification?.title}');
      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'Notifications générales',
      channelDescription: 'Notifications de l\'application AVS_Saver',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nouvelle notification',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  /// Gérer le tap sur une notification
  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tappée: ${response.payload}');
    // TODO: Navigation basée sur le payload
    _handleNotificationNavigation(response.payload);
  }

  /// Gérer l'ouverture de l'app via une notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App ouverte via notification: ${message.data}');
    _handleNotificationNavigation(message.data.toString());
  }

  /// Navigation basée sur les données de notification
  void _handleNotificationNavigation(String? data) {
    if (data == null) return;

    try {
      // Parser les données et naviguer en conséquence
      // TODO: Implémenter la logique de navigation
      print('Navigation vers: $data');
    } catch (e) {
      print('Erreur navigation notification: $e');
    }
  }

  /// Sauvegarder le token FCM en base
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = await _databaseService.getCurrentUser();
      if (user != null) {
        await _databaseService.updateUserProfile(user.id, {
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur sauvegarde token: $e');
    }
  }

  /// Envoyer une notification à un utilisateur spécifique
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Récupérer le token de l'utilisateur
      final userProfile = await _databaseService.getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('Utilisateur introuvable');
      }

      // TODO: Appeler votre backend pour envoyer via FCM Admin SDK
      // Car l'envoi direct depuis le client n'est pas sécurisé

      // En attendant, sauvegarder en base pour consultation
      await _saveNotificationToDatabase(
        userId: userId,
        title: title,
        body: body,
        data: data,
      );

      print('Notification envoyée à $userId');
    } catch (e) {
      print('Erreur envoi notification: $e');
    }
  }

  /// Sauvegarder une notification en base
  Future<void> _saveNotificationToDatabase({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _databaseService.addNotification(
        userId: userId,
        title: title,
        body: body,
        data: data ?? {},
      );
    } catch (e) {
      print('Erreur sauvegarde notification: $e');
    }
  }

  /// Notifications prédéfinies pour l'app

  /// Notification nouvelle réservation
  Future<void> notifyNewBooking({
    required String coordinatorId,
    required String familyName,
    required String avsName,
  }) async {
    await sendNotificationToUser(
      userId: coordinatorId,
      title: 'Nouvelle demande de réservation',
      body: '$familyName souhaite réserver $avsName',
      data: {
        'type': AppConstants.notifNewBooking,
        'action': 'open_coordinator_screen',
      },
    );
  }

  /// Notification réservation confirmée
  Future<void> notifyBookingConfirmed({
    required String familyId,
    required String avsName,
    required DateTime scheduledTime,
  }) async {
    await sendNotificationToUser(
      userId: familyId,
      title: 'Réservation confirmée',
      body: 'Votre réservation avec $avsName est confirmée pour le ${_formatDateTime(scheduledTime)}',
      data: {
        'type': AppConstants.notifBookingConfirmed,
        'action': 'open_agenda',
      },
    );
  }

  /// Notification nouveau message
  Future<void> notifyNewMessage({
    required String receiverId,
    required String senderName,
    required String messagePreview,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: 'Nouveau message de $senderName',
      body: messagePreview,
      data: {
        'type': AppConstants.notifNewMessage,
        'action': 'open_messages',
        'senderId': senderName,
      },
    );
  }

  /// Notification rappel de mission
  Future<void> notifyMissionReminder({
    required String avsId,
    required String beneficiaryName,
    required DateTime missionTime,
  }) async {
    await sendNotificationToUser(
      userId: avsId,
      title: 'Rappel de mission',
      body: 'Mission avec $beneficiaryName dans 30 minutes',
      data: {
        'type': AppConstants.notifMissionReminder,
        'action': 'open_agenda',
      },
    );
  }

  /// Programmer des notifications locales (rappels)
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, String>? data,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'scheduled_notifications',
      'Rappels programmés',
      channelDescription: 'Rappels de missions et rendez-vous',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      details,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: data?.toString(),
    );
  }

  /// Annuler une notification programmée
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Obtenir le token FCM actuel
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// S'abonner à un topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Abonné au topic: $topic');
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Désabonné du topic: $topic');
  }

  /// S'abonner aux topics basés sur le rôle
  Future<void> subscribeToRoleBasedTopics(String userRole) async {
    // Topic général
    await subscribeToTopic(AppConstants.fcmTopicAll);

    // Topics spécifiques au rôle
    switch (userRole) {
      case AppConstants.roleAvs:
        await subscribeToTopic(AppConstants.fcmTopicAvs);
        break;
      case AppConstants.roleFamille:
        await subscribeToTopic(AppConstants.fcmTopicFamilies);
        break;
      case AppConstants.roleCoordinateur:
        await subscribeToTopic(AppConstants.fcmTopicCoordinators);
        break;
    }
  }

  /// Vérifier si les notifications sont activées
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Ouvrir les paramètres de notifications
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  // ==================== HELPERS ====================

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // TODO: Implémenter la conversion avec timezone
    // Nécessite le package 'timezone'
    return TZDateTime.from(dateTime, getLocation('Europe/Paris'));
  }

  /// Nettoyer les ressources
  void dispose() {
    // Nettoyer si nécessaire
  }
}