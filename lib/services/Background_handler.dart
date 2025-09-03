import 'package:firebase_messaging/firebase_messaging.dart';

/// Handler pour les messages Firebase reçus en arrière-plan
/// Cette fonction doit être une fonction de niveau supérieur (top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Message reçu en arrière-plan : ${message.notification?.title}');

  // Ici vous pouvez ajouter la logique pour traiter les notifications en arrière-plan
  // Par exemple : sauvegarder en base locale, déclencher une action, etc.

  if (message.notification != null) {
    print('Titre: ${message.notification!.title}');
    print('Corps: ${message.notification!.body}');
  }

  // Traitement des données personnalisées
  if (message.data.isNotEmpty) {
    print('Données: ${message.data}');
  }
}