import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Envoyer un message
  Future<void> sendMessage(
      String receiverId, String text, String senderId) async {
    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Ajouter le message à Firestore
    await _firestore.collection('messages').add(messageData);

    // Envoyer une notification push via FCM (si l'utilisateur n'est pas en ligne)
    String? receiverToken = await getUserToken(
        receiverId); // Implémentez une fonction pour récupérer le token FCM de l'utilisateur
    if (receiverToken != null) {
      // Utilisez l'API FCM côté serveur pour envoyer la notification (pas directement depuis l'app pour la sécurité)
      // Exemple : Appelez une Cloud Function ou votre backend pour envoyer via admin SDK
      print('Notification envoyée à $receiverId');
    }
  }

  // Écouter les messages en temps réel pour un utilisateur
  Stream<QuerySnapshot> getMessages(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Fonction exemple pour récupérer le token FCM (stockez-le dans Firestore par utilisateur)
  Future<String?> getUserToken(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc['fcmToken'];
  }
}
